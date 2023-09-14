//
//  BottleRenameView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 05/04/2023.
//

import SwiftUI
import WhiskyKit

struct BottleRenameView: View {
    let bottle: Bottle
    @State var newBottleName: String = ""
    @State var nameValid: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("rename.title")
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
