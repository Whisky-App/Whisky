//
//  BottleCreationView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import SwiftUI

struct BottleCreationView: View {
    @State var newBottleName: String = ""
    @State var newBottleVersion: WinVersion = .win10
    @State var invalidBottleNameDescription: String = ""
    @State var invalidBottleName: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("create.title")
                    .bold()
                Spacer()
            }
            Divider()
            HStack(alignment: .top) {
                Text("create.name")
                Spacer()
                TextField("", text: $newBottleName)
                .onChange(of: newBottleName) { _ in
                    invalidBottleName = false
                }
                .frame(width: 180)
            }
            HStack {
                Text("create.win")
                Spacer()
                Picker("", selection: $newBottleVersion) {
                    ForEach(WinVersion.allCases.reversed(), id: \.self) {
                        Text($0.pretty())
                    }
                }
                .labelsHidden()
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
                    .opacity(invalidBottleName ? 1 : 0)
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("create.create") {
                    (invalidBottleName, invalidBottleNameDescription) = BottleVM
                        .shared
                        .validateBottleName(bottleName: newBottleName)
                    if invalidBottleName {
                        return
                    }
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

struct BottleCreationView_Previews: PreviewProvider {
    static var previews: some View {
        BottleCreationView()
    }
}
