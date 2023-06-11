//
//  WatchNumpad.swift
//  expenseTrackerWatch Watch App
//
//  Created by Mason on 6/10/23.
//

import SwiftUI

struct NumpadButton: View {
    private var value: String
    @Binding private var entry: String
    private let isZero: Bool
    private let isDecimalPoint: Bool
    
    init(_ value: String, entry: Binding<String>) {
        self.value = value
        self._entry = entry
        self.isZero = false
        self.isDecimalPoint = false
    }

    init(_ value: String, entry: Binding<String>, isZero: Void) {
        self.value = value
        self._entry = entry
        self.isZero = true
        self.isDecimalPoint = false
    }

    init(_ value: String, entry: Binding<String>, isDecimalPoint: Void) {
        self.value = value
        self._entry = entry
        self.isZero = false
        self.isDecimalPoint = true
    }
    
    var body: some View {
        Button {
            // some logic for 0 and decimal point
            if self.isZero {
                if self.$entry.wrappedValue == "" {
                    
                } else {
                    self.$entry.wrappedValue.append(self.value)
                }
            } else if self.isDecimalPoint {
                if self.$entry.wrappedValue.contains(self.value) {
                    
                } else if self.$entry.wrappedValue == "" {
                    self.$entry.wrappedValue.append("0\(self.value)")
                } else {
                    self.$entry.wrappedValue.append(self.value)
                }
            } else {
                self.$entry.wrappedValue.append(self.value)
            }
        } label: {
            Text(self.value)
                .font(.title2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension String {
    mutating func nonStupidRemoveLast() {
        if !self.isEmpty {
            self.removeLast()
        }
    }
}

struct NumpadDeleteButton: View {
    @Binding private var entry: String
    
    init(entry: Binding<String>) {
        self._entry = entry
    }
    
    var body: some View {
        Button {
            self.$entry.wrappedValue.nonStupidRemoveLast()
            if self.$entry.wrappedValue == "0" {
                self.$entry.wrappedValue = ""
            }
        } label: {
            if self.$entry.wrappedValue != "" {
                Image(systemName: "delete.left.fill")
                    .frame(width: 25, alignment: .bottomTrailing)
                    .foregroundColor(Color.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WatchNumpad: View {
    @State private var entry: String = ""
    private var decimalPoint: String
    private let callback: (Float) -> Void
    
    public init(_ callback: @escaping (Float) -> Void) {
        self.callback = callback
        self.decimalPoint = NumberFormatter().decimalSeparator ?? "."
    }
    
    var body: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            GridRow {
                Text(" ")
            }
            GridRow {
                HStack(spacing: 0) {
                    Group {
                        if entry.count > 0 {
                            Text(entry)
                        } else {
                            Text(" ")
                        }
                    }
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    NumpadDeleteButton(entry: $entry)
                }
                    .gridCellColumns(3)
            }
            GridRow {
                // button row 1 (7,8,9)
                NumpadButton("7", entry: $entry)
                NumpadButton("8", entry: $entry)
                NumpadButton("9", entry: $entry)
            }
            GridRow {
                // button row 2 (4,5,6)
                NumpadButton("4", entry: $entry)
                NumpadButton("5", entry: $entry)
                NumpadButton("6", entry: $entry)
            }
            GridRow {
                // button row 3 (1,2,3)
                NumpadButton("1", entry: $entry)
                NumpadButton("2", entry: $entry)
                NumpadButton("3", entry: $entry)
            }
            GridRow {
                // button row 4 (0, decimal point, done button)
                NumpadButton("0", entry: $entry, isZero: ())
                NumpadButton(decimalPoint, entry: $entry, isDecimalPoint: ())
                Button {
                    callback(Float(entry) ?? 0)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct WatchNumpad_Previews: PreviewProvider {
    static var previews: some View {
        WatchNumpad() { _ in
            
        }
    }
}
