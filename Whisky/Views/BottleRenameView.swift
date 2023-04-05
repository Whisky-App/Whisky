//
//  BottleRenameView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 05/04/2023.
//

import SwiftUI

struct BottleRenameView: View {
    @State var newBottleName: String = ""
    @State var newBottleVersion: WinVersion = .win7
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("create.title")
                    .bold()
                Spacer()
            }
            Divider()
            HStack {
                Text("create.name")
                Spacer()
                TextField("", text: $newBottleName)
                    .frame(width: 180)
            }
            HStack {
                Text("create.win")
                Spacer()
                Picker("", selection: $newBottleVersion) {
                    ForEach(WinVersion.allCases, id: \.self) {
                        Text($0.pretty())
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("create.create") {
                    BottleVM.shared.createNewBottle(bottleName: newBottleName,
                                                    winVersion: newBottleVersion)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350, height: 150)
    }
}

struct BottleRenameView_Previews: PreviewProvider {
    static var previews: some View {
        BottleRenameView()
    }
}
