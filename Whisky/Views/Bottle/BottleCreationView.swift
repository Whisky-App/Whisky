//
//  BottleCreationView.swift
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

struct BottleCreationView: View {
    @State var newBottleName: String = ""
    @State var newBottleVersion: WinVersion = .win10
    @State var newBottleURL: URL = BottleData.defaultBottleDir
    @State var bottlePath: String = ""
    @State var nameValid: Bool = false
    @Binding var newlyCreatedBottleURL: URL?
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
                TextField(String(), text: $newBottleName)
                    .frame(width: 180)
                    .onChange(of: newBottleName) { _, name in
                        nameValid = !name.isEmpty
                    }
            }
            HStack {
                Text("create.win")
                Spacer()
                Picker(String(), selection: $newBottleVersion) {
                    ForEach(WinVersion.allCases.reversed(), id: \.self) {
                        Text($0.pretty())
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
            HStack {
                Text("create.path")
                Spacer()
                Text(bottlePath)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .help(bottlePath)
                Button("create.browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = true
                    panel.directoryURL = BottleData.containerDir
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                newBottleURL = url
                            }
                        }
                    }
                }
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("create.create") {
                    newlyCreatedBottleURL = BottleVM.shared.createNewBottle(bottleName: newBottleName,
                                                    winVersion: newBottleVersion,
                                                    bottleURL: newBottleURL)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!nameValid)
            }
        }
        .padding()
        .onChange(of: newBottleURL) {
            bottlePath = newBottleURL.prettyPath()
        }
        .onAppear {
            bottlePath = newBottleURL.prettyPath()
        }
        .frame(width: 400, height: 180)
    }
}

#Preview {
    BottleCreationView(newlyCreatedBottleURL: .constant(nil))
}
