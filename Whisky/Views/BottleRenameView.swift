//
//  BottleRenameView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 05/04/2023.
//

import SwiftUI

struct BottleRenameView: View {
    let bottle: Bottle
    @State var newBottleName: String = ""
    @State var invalidBottleNameDescription: String = ""
    @State var invalidBottleName: Bool = false
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
                VStack(alignment: .leading) {
                    TextField("", text: $newBottleName)
                        .onChange(of: newBottleName) { _ in
                            invalidBottleName = false
                        }
                    if invalidBottleName {
                        Text(invalidBottleNameDescription)
                            .foregroundColor(.red)
                            .font(.system(.footnote))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)

                    }
                }
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
                    (invalidBottleName, invalidBottleNameDescription) = BottleVM.shared.validateBottleName(bottleName: newBottleName)
                    if invalidBottleName {
                        return
                    }
                    bottle.rename(newName: newBottleName)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 370, height: 150)
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
