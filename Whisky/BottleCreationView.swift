//
//  BottleCreationView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import SwiftUI

struct BottleCreationView: View {
    @Binding var showBottleCreation: Bool
    @State var newBottleName: String = ""
    @State var newBottleVersion: WinVersion = .win7

    var body: some View {
        VStack {
            HStack {
                Text("Create a new bottle")
                    .bold()
                Spacer()
            }
            Divider()
            HStack {
                Text("Bottle name:")
                Spacer()
                TextField("", text: $newBottleName)
                    .frame(width: 180)
            }
            HStack {
                Text("Windows version:")
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
                Button("Create") {
                    BottleVM.shared.createNewBottle(bottleName: newBottleName,
                    winVersion: newBottleVersion)
                    showBottleCreation.toggle()
                }
            }
        }
        .padding()
        .frame(width: 350, height: 150)
    }
}

struct BottleCreationView_Previews: PreviewProvider {
    static var previews: some View {
        BottleCreationView(showBottleCreation: .constant(true))
    }
}
