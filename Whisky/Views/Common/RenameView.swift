//
//  RenameView.swift
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

struct RenameView: View {
    let title: Text
    var renameAction: (String) -> Void

    @State private var name: String = ""
    @Environment(\.dismiss) private var dismiss

    init(_ title: LocalizedStringKey, name: String, renameAction: @escaping (String) -> Void) {
        self.title = Text(title)
        self._name = State(initialValue: name)
        self.renameAction = renameAction
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("rename.name", text: $name)
            }
            .formStyle(.grouped)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("create.cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("rename.rename") {
                        submit()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isNameValid)
                }
            }
            .onSubmit {
                submit()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: ViewWidth.small)
    }

    var isNameValid: Bool {
        !name.isEmpty
    }

    func submit() {
        renameAction(name)
        dismiss()
    }
}
