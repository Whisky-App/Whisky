//
//  PinRenameView.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import SwiftUI

struct PinRenameView: View {
    @Binding var name: String

    @State private var newPinName: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("rename.name", text: $newPinName)
            }
            .formStyle(.grouped)
            .navigationTitle("rename.pin.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("create.cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("rename.rename") {
                        name = newPinName
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isNameValid)
                }
            }
        }
        .frame(width: 350, height: 120)
        .onAppear {
            newPinName = name
        }
    }

    var isNameValid: Bool {
        !name.isEmpty
    }
}
