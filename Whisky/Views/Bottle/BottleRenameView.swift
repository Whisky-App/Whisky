//
//  BottleRenameView.swift
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
import WhiskyKit

struct BottleRenameView: View {
    let bottle: Bottle
    @State var newBottleName: String = ""
    @State var nameValid: Bool = false
    @Binding var name: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("rename.bottle.title")
                    .bold()
                Spacer()
            }
            Divider()
            HStack(alignment: .top) {
                Text("rename.name")
                Spacer()
                TextField(String(), text: $newBottleName)
                    .frame(width: 180)
                    .onChange(of: newBottleName) { _, name in
                        nameValid = !name.isEmpty
                    }
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("rename.rename") {
                    name = newBottleName
                    bottle.rename(newName: newBottleName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!nameValid)
            }
        }
        .padding()
        .frame(width: 350, height: 150)
        .onAppear {
            newBottleName = bottle.settings.name
        }
    }
}
