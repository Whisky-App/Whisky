//
//  FileOpenView.swift
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

struct FileOpenView: View {
    var fileURL: URL
    var currentBottle: URL?
    var bottles: [Bottle]
    @State var selection: URL = URL(filePath: "")
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text(String(format: String(localized: "run.title"),
                            fileURL.lastPathComponent))
                    .bold()
                Spacer()
            }
            Divider()
            HStack {
                Text("run.bottle")
                Spacer()
                Picker(String(), selection: $selection) {
                    ForEach(bottles, id: \.self) {
                        Text($0.settings.name)
                            .tag($0.url)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("button.run") {
                    if let bottle = bottles.first(where: { $0.url == selection}) {
                        Task.detached(priority: .userInitiated) {
                            do {
                                if fileURL.pathExtension == "bat" {
                                    try await Wine.runBatchFile(url: fileURL,
                                                                bottle: bottle)
                                } else {
                                    try await Wine.runExternalProgram(url: fileURL,
                                                                      bottle: bottle)
                                }
                            } catch {
                                print(error)
                            }
                        }
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 180)
        .onAppear {
            selection = bottles.first(where: {$0.url == currentBottle})?.url ?? bottles[0].url
        }
    }
}
