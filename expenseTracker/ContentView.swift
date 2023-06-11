//
//  ContentView.swift
//  expenseTracker
//
//  Created by Mason on 6/10/23.
//

import SwiftUI

struct ExpenseDetailView: View {
    // core data
    @FetchRequest(sortDescriptors: [SortDescriptor(\.creationDate)]) var expenseCategories: FetchedResults<ExpenseCategory>
    @Environment(\.managedObjectContext) var moc

    // state stuff
    @Environment(\.presentationMode) var presentationMode
    private struct ExpenseEditData {
        var amount: String
        var desc: String
        var date: Date
        var category: ExpenseCategory?
    }
    @State private var entry: ExpenseEditData
    private var expense: Expense?

    var body: some View {
        Form {
            TextField("Description", text: $entry.desc)
            Picker("Category", selection: $entry.category) {
                Text("(none)").tag(Optional<ExpenseCategory>(nil)).foregroundColor(.secondary)
                ForEach(expenseCategories) { expenseCategory in
                    Text(expenseCategory.displayName ?? "").tag(Optional(expenseCategory))
                }
            }
            TextField("Amount", text: $entry.amount)
                .keyboardType(.decimalPad)
            DatePicker("Date", selection: $entry.date)
            Section {
                Button("Delete", role: .destructive) {
                    if let expense = expense {
                        moc.delete(expense)
                        try? moc.save()
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
            .toolbar {
                Button("Save") {
                    if let expense = expense {
                        // editing existing
                        expense.amount = Float(entry.amount) ?? 0
                        expense.desc = entry.desc
                        expense.date = entry.date
                        expense.category = entry.category
                    } else {
                        // new expense
                        let expense = Expense(context: moc)
                        expense.amount = Float(entry.amount) ?? 0
                        expense.desc = entry.desc
                        expense.date = entry.date
                        expense.category = entry.category
                    }
                    
                    // save changes
                    try? moc.save()

                    // hide self
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle(expense != nil ? "Edit Expense" : "Add Expense")
    }

    public init(_ expense: Expense?) {
        var entry: ExpenseEditData
        if let expense = expense {
            // we can soft ignore errors here
            entry = ExpenseEditData(amount: "\(expense.amount)", desc: expense.desc ?? "", date: expense.date ?? Date(), category: expense.category)
        } else {
            // new expense
            entry = ExpenseEditData(amount: "", desc: "", date: Date())
        }
        self._entry = State(initialValue: entry)
        self.expense = expense
    }
}

struct ExpenseListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)]) var expenses: FetchedResults<Expense>
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack {
            List() {
                Section(header: Text("Expenses")) {
                    ForEach(expenses) { expense in
                        NavigationLink {
                            ExpenseDetailView(expense)
                        } label: {
                            HStack {
                                VStack {
                                    Text(expense.desc ?? "(unknown)")
                                        .font(.title3)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(expense.category?.displayName ?? "(unsorted)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("$\(String(format: "%.2f", expense.amount))")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteExpense(expense)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }.headerProminence(.increased)
                
                NavigationLink {
                    ExpenseDetailView(nil)
                } label: {
                    Label("Add Expense", systemImage: "plus")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        moc.delete(expense)
        try? moc.save()
    }
}

struct PreferencesView: View {
    // core data
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var expenses: FetchedResults<Expense>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.creationDate)]) var expenseCategories: FetchedResults<ExpenseCategory>

    // watch communication
    @StateObject var commsMgr = CommunicationManager()
    
    // misc state stuff for the modal
    @State private var currentExpenseCategoryDisplay: String = ""
    @State private var currentExpenseCategory: ExpenseCategory?
    @State private var presentAlert = false

    var body: some View {
        List() {
            Section(header: Text("Manage Categories"), footer: Text("Expenses are organized by these categories. Categories are displayed in order of creation. Tap on a category to modify its name, and swipe to delete. Modifying a category's name will update the corresponding category name for all other expenses. Deleting a category will set all expenses in that category to the unsorted category.")) {
                ForEach(expenseCategories) { expenseCategory in
                    Button() {
                        currentExpenseCategory = expenseCategory
                        currentExpenseCategoryDisplay = expenseCategory.displayName ?? ""
                        presentAlert = true
                    } label: {
                        Text((expenseCategory.displayName ?? "")
                             != "" ?  (expenseCategory.displayName ?? "") : "(blank)")
                            .foregroundColor((expenseCategory.displayName ?? "")
                                             != "" ? .primary : .secondary)
                    }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteExpenseCategory(expenseCategory)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                }

                Button() {
                    // clear the values
                    currentExpenseCategoryDisplay = ""
                    currentExpenseCategory = nil
                    // display empty alert
                    presentAlert = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
            .headerProminence(.increased)
            
            Section(header: Text("Miscellaneous")) {
                Button() {
                    print("TODO")
                    
                    DispatchQueue.global().async {
                        print("todo: do compute here?")
                        
                        DispatchQueue.main.async {
                            // TODO: actually implement this
                            print("todo: display the share sheet or whatever here")
                        }
                    }
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }

                if commsMgr.initializedSucessfully {
                    Button {
                        commsMgr.syncCategories(expenseCategories.map({ ec in
                            ec
                        }))
                    } label: {
                        Label("Synchronize categories to Watch", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .headerProminence(.increased)
        }.alert(((currentExpenseCategory != nil) ? "Edit" : "New"), isPresented: $presentAlert) {
            // alert modal to modify category name
            TextField("Category Name", text: $currentExpenseCategoryDisplay)
            
            Button("Save") {
                if let ec = currentExpenseCategory {
                    // editing existing
                    ec.displayName = currentExpenseCategoryDisplay
                } else {
                    // new expense category
                    let ec = ExpenseCategory(context: moc)
                    ec.displayName = currentExpenseCategoryDisplay
                    ec.creationDate = Date()
                }
                try? moc.save()
                
                // clear values
                currentExpenseCategory = nil
            }
            Button("Cancel", role: .cancel) {}
        }.onReceive(commsMgr.dataSubject) { serializedExpense in
            // core data context
            let psc = moc.persistentStoreCoordinator

            // make the expense
            let expense = Expense(context: moc)
            expense.amount = serializedExpense.amount
            expense.desc = serializedExpense.desc
            expense.date = serializedExpense.date

            // find the right category
            if let categoryUrl = URL(string: serializedExpense.categoryId),
               let catId = psc?.managedObjectID(forURIRepresentation: categoryUrl),
               let obj = try? moc.existingObject(with: catId),
               let category = obj as? ExpenseCategory {
                expense.category = category
            }

            // try saving?
            DispatchQueue.main.async {
                try? moc.save()
            }
        }
    }
    
    func deleteExpenseCategory(_ expenseCategory: ExpenseCategory) {
        moc.delete(expenseCategory)
        try? moc.save()
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign")
                }
            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    //@StateObject private var dataController = DataController()

    static var previews: some View {
        ContentView()
            //.environment(\.managedObjectContext, dataController.container.viewContext)
    }
}
