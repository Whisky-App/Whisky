//
//  FileOpenView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 11/09/2023.
//

import SwiftUI

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
