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
    @State var isValidBottleName: Bool = true
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
                TextField("", text: $newBottleName)
                    .onChange(of: newBottleName) { _ in
                        isValidBottleName = true
                    }
                    .frame(width: 180)
            }
            Spacer()
            HStack {
                Text(invalidBottleNameDescription)
                    .foregroundColor(.red)
                    .font(.system(.footnote))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                    .frame(height: 30, alignment: .center)
                    .opacity(isValidBottleName ? 0 : 1)
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("rename.rename") {
                    if case .failure(let failureReason) = BottleVM.shared.isValidBottleName(bottleName: newBottleName) {
                        isValidBottleName = false
                        invalidBottleNameDescription = failureReason.description
                        return
                    }
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
