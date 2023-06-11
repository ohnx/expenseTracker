//
//  DataController.swift
//  expenseTracker
//
//  Created by Mason on 6/10/23.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    let container = NSPersistentContainer(name: "ExpenseTracker")
    
    init() {
        container.loadPersistentStores { description, err in
            if let err = err {
                print("Core data load failed: \(err.localizedDescription)")
            }
        }
    }
}
