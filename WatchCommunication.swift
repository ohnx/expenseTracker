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
        DispatchQueue.main.async {
            // try to decode as serializedexpense
            if let expenseData = message["expense"] as? Data {
                let decoder = JSONDecoder()
                if let expense = try? decoder.decode(SerializedExpense.self, from: expenseData) {
                    // broadcast this update
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
            session?.sendMessage(["expense": encodedData], replyHandler: nil) { error in
                // TODO: bubble this up to the user in some way
                print(error.localizedDescription)
            }
        }
    }
    #endif
}

#if os(iOS)
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
            dataSubject.send(categories)
        }
    }
    
    func sendExpense(_ expense: SerializedExpense) {
        self.delegate?.sendExpense(expense)
    }
}

#endif
