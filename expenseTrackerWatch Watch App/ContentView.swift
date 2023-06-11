//
//  ContentView.swift
//  expenseTrackerWatch Watch App
//
//  Created by Mason on 6/10/23.
//

import SwiftUI

struct ContentView: View {
    // local state
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var amount: String = ""
    @Environment(\.presentationMode) var presentationMode

    // phone communication manager
    @StateObject var commsMgr = CommunicationManager()

    var body: some View {
        // super cursed
        NavigationStack {
            VStack {
                TextField("Description", text: $description)
                Spacer()
                NavigationLink {
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
                                WatchNumpad { value in
                                    commsMgr.sendExpense(SerializedExpense(amount: value, desc: description, date: Date(), categoryId: category))
                                    // TODO: view doesn't dismiss
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                        } label: {
                            Text("Next")
                        }
                    }
                } label: {
                    Text("Next")
                }
            }
            .padding()
            .navigationTitle(Text("Expense Tracker"))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
