//
//  WatchCommunication.swift
//  expenseTracker
//
//  Created by Mason on 6/10/23.
//

import Foundation
import WatchConnectivity
import Combine
import CoreData

struct SerializedExpense: Codable {
    let amount: Float
    let desc: String
    let date: Date
    let categoryId: String
}

struct SerializedCategory: Codable, Identifiable {
    let id: String
    let name: String
}

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    //init() {
    //super.init()
    //}
    private var session: WCSession?
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        self.session = session
    }

    #if os(iOS)
    // more boilerplate needed for ios
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // i think we need to do this to activate the new session with the other apple watch?
        session.activate()
    }

    // ios app receives messages
    let dataSubject: PassthroughSubject<SerializedExpense, Never>
    
    init(_ dataSubject: PassthroughSubject<SerializedExpense, Never>) {
        self.dataSubject = dataSubject
        super.init()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("did receive message")
        DispatchQueue.main.async {
            // try to decode as serializedexpense
            print("did receive message 2 \(message)")
            if let expenseData = message["expense"] as? Data {
                let decoder = JSONDecoder()
                if let expense = try? decoder.decode(SerializedExpense.self, from: expenseData) {
                    // broadcast this update
                    print("todo: update??")
                    self.dataSubject.send(expense)
                } else {
                    print("some sort of communication error :(")
                }
            } else {
                print("some sort of communication error :(")
            }
        }
    }
    
    // ios app sends application contexts
    func sendCategories(_ categories: [ExpenseCategory]) {
        var serializedCategories = [SerializedCategory]()
        
        for category in categories {
            serializedCategories.append(SerializedCategory(id: category.objectID.uriRepresentation().absoluteString, name: category.displayName ?? ""))
        }
        
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(serializedCategories) {
            if let _ = try? session?.updateApplicationContext(["categories": encodedData]) {
            } else {
                print("failed to send data to watch")
            }
        }
    }
    #else
    // watchos app receives application contexts
    let dataSubject: CurrentValueSubject<[SerializedCategory], Never>
    
    init(_ dataSubject: CurrentValueSubject<[SerializedCategory], Never>) {
        self.dataSubject = dataSubject
        super.init()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let categoriesData = applicationContext["categories"] as? Data {
                // try decode
                let decoder = JSONDecoder()
                if let categories = try? decoder.decode([SerializedCategory].self, from: categoriesData) {
                    // decode succeeded!
                    self.dataSubject.send(categories)
                    // also store the data in UserDefaults
                    UserDefaults.standard.set(categoriesData, forKey: "categories")
                } else {
                    print("some sort of communication error :(")
                }
            } else {
                print("some sort of communication error :(")
            }
        }
    }
    
    // watchos app sends messages
    func sendExpense(_ expense: SerializedExpense) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(expense) {
            print("Encoded data \(String(decoding: encodedData, as: UTF8.self))")
            session?.sendMessage(["expense": encodedData], replyHandler: nil) { error in
                print(error.localizedDescription)
            }
        }
    }
    #endif
}

#if os(iOS)
class ExpenseAddSubscriber: Subscriber {
    typealias Input = SerializedExpense
    typealias Failure = Never
    
    // awful hack
    lazy var dataContainer :NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseTracker")
        
        container.loadPersistentStores { description, err in
            if let err = err {
                print("Core data load failed: \(err.localizedDescription)")
            }
        }

        return container
    }()

    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    func receive(_ serializedExpense: SerializedExpense) -> Subscribers.Demand {
        // core data context
        let moc = self.dataContainer.viewContext
        let psc = self.dataContainer.persistentStoreCoordinator

        // make the expense
        let expense = Expense(context: moc)
        expense.amount = serializedExpense.amount
        expense.desc = serializedExpense.desc
        expense.date = serializedExpense.date

        // find the right category
        if let categoryUrl = URL(string: serializedExpense.categoryId),
           let catId = psc.managedObjectID(forURIRepresentation: categoryUrl),
           let obj = try? moc.existingObject(with: catId),
           let category = obj as? ExpenseCategory {
            print("successfully found the category lmao \(category.debugDescription)")
            expense.category = category
        }
        
        // TODO: this is completely broken rn
        print("adding expense!: \(expense)")
        
        // try saving?
        DispatchQueue.main.async {
            try? moc.save()
        }

        return .none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completion event:", completion)
    }
}

class CommunicationManager: ObservableObject {
    var session: WCSession?
    let delegate: WatchSessionDelegate?
    let dataSubject = PassthroughSubject<SerializedExpense, Never>()
    
    @Published private(set) var initializedSucessfully: Bool = false

    init(session: WCSession = .default) {
        if WCSession.isSupported() {
            let delegate = WatchSessionDelegate(dataSubject)
            self.session = session
            self.delegate = delegate

            // get the data ready
            dataSubject.subscribe(ExpenseAddSubscriber())

            session.delegate = delegate
            session.activate()
            self.initializedSucessfully = true
        } else {
            self.session = nil
            self.delegate = nil
            self.initializedSucessfully = false
        }
    }

    public func syncCategories(_ categories: [ExpenseCategory]) {
        self.delegate?.sendCategories(categories)
    }
}
#else
class CommunicationManager: ObservableObject {
    var session: WCSession?
    let delegate: WatchSessionDelegate?
    let dataSubject = CurrentValueSubject<[SerializedCategory], Never>([])

    @Published private(set) var initializedSucessfully: Bool = false
    @Published private(set) var categories: [SerializedCategory] = []

    init(session: WCSession = .default) {
        if WCSession.isSupported() {
            let delegate = WatchSessionDelegate(dataSubject)
            self.session = session
            self.delegate = delegate
            session.delegate = delegate
            session.activate()
            self.initializedSucessfully = true
        } else {
            self.session = nil
            self.delegate = nil
            self.initializedSucessfully = false
        }
        
        dataSubject
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
        
        // try decode categories
        let decoder = JSONDecoder()
        if let categoriesData = UserDefaults.standard.data(forKey: "categories"),
           let categories = try? decoder.decode([SerializedCategory].self, from: categoriesData) {
            // decode succeeded!
            print("decoded categories!")
            dataSubject.send(categories)
        }
    }
    
    func sendExpense(_ expense: SerializedExpense) {
        self.delegate?.sendExpense(expense)
    }
}

#endif
