//
//  ContentView.swift
//  expenseTrackerWatch Watch App
//
//  Created by Mason on 6/10/23.
//

import SwiftUI
import Combine

struct ContentView: View {
    // local state
    @State private var category: String = ""
    @State private var description: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var path = NavigationPath()

    // phone communication manager
    @StateObject var commsMgr = CommunicationManager()

    // weird combine stuff for messaging
    let entrySubmitted = PassthroughSubject<Float, Never>()
    
    var body: some View {
        // super cursed
        NavigationStack(path: $path) {
            VStack {
                TextField("Description", text: $description)
                Spacer()
                NavigationLink(value: "category") {
                    Text("Next")
                }.navigationDestination(for: String.self) { _ in
                    VStack {
                        Picker("Category", selection: $category) {
                            Text("(none)").tag("").foregroundColor(.secondary)
                            ForEach(commsMgr.categories) { expenseCategory in
                                Text(expenseCategory.name).tag(expenseCategory.id)
                            }
                        }
                            .pickerStyle(InlinePickerStyle())
                        NavigationLink {
                            VStack {
                                WatchNumpad(entrySubmitted)
                            }
                        } label: {
                            Text("Next")
                        }
                    }
                }
            }
            .padding()
            .navigationTitle(Text("Expense Tracker"))
        }.onReceive(entrySubmitted) { value in
            // send expense to watch
            commsMgr.sendExpense(SerializedExpense(amount: value, desc: description, date: Date(), categoryId: category))

            // clear values
            self.description = ""
            self.category = ""

            // dismiss view
            self.path.removeLast(self.path.count)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
