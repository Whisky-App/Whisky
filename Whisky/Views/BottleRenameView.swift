//
//  BottleRenameView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 05/04/2023.
//

import SwiftUI

struct BottleRenameView: View {
    @State var bottle: Bottle
    @State var newBottleName: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("rename.title")
                    .bold()
                Spacer()
            }
            Divider()
            HStack {
                Text("rename.name")
                Spacer()
                TextField("", text: $newBottleName)
                    .frame(width: 180)
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
            }
        }
        .padding()
        .frame(width: 350, height: 150)
        .onAppear {
            newBottleName = bottle.name
        }
    }
}

struct BottleRenameView_Previews: PreviewProvider {
    static var previews: some View {
        BottleRenameView(bottle: Bottle())
    }
}
