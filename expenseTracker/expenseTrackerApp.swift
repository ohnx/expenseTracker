//
//  expenseTrackerApp.swift
//  expenseTracker
//
//  Created by Mason on 6/10/23.
//

import SwiftUI

@main
struct expenseTrackerApp: App {
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
