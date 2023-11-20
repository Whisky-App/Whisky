//
//  PinCreationView.swift
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
import UniformTypeIdentifiers
import WhiskyKit

struct PinCreationView: View {
    let bottle: Bottle
    @State var newPinURL: URL?
    @State private var newPinName: String = ""
    @State private var isDuplicate: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text("pin.title")
                .bold()
            Divider()
            HStack {
                Text("pin.name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField(String(), text: $newPinName)
                    .frame(width: 180)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("pin.path")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("create.browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe,
                                                 UTType(exportedAs: "com.microsoft.msi-installer"),
                                                 UTType(exportedAs: "com.microsoft.bat")]
                    panel.directoryURL = newPinURL ?? bottle.url.appending(path: "drive_c")
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false

                    guard panel.runModal() == .OK,
                          let url = panel.urls.first else { return }
                    newPinURL = url
                }
            }
            if let newPinURL {
                Text(newPinURL.prettyPath())
                    .truncationMode(.middle)
                    .lineLimit(2, reservesSpace: true)
                    .help(newPinURL.prettyPath())
            }
            HStack {
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .frame(maxWidth: .infinity, alignment: .trailing)
                Button("pin.create") {
                    guard let newPinURL else { return }

                    // Ensure this pin doesn't already exist
                    guard !bottle.settings.pins.contains(where: { $0.url == newPinURL })
                    else {
                        isDuplicate = true
                        return
                    }

                    bottle.settings.pins.append(PinnedProgram(name: newPinName, url: newPinURL))

                    // Trigger a reload
                    bottle.updateInstalledPrograms()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newPinName.isEmpty || newPinURL == nil)
                .alert("pin.error.title",
                    isPresented: $isDuplicate
                ) {}
                message: {
                    Text("pin.error.duplicate.\(newPinURL?.lastPathComponent ?? "unknown")")
                }
            }
        }
        .onChange(of: newPinURL, initial: true) { oldValue, newValue in
            guard newValue != nil else { return }

            // Only reset newPinName if the textbox hasn't been modified
            if newPinName.isEmpty ||
               newPinName == oldValue?.deletingPathExtension().lastPathComponent {

                newPinName = newValue?.deletingPathExtension().lastPathComponent ?? ""
            }
        }
        .padding()
        .frame(width: 400)
    }
}

struct PinButtonView: View {
    let bottle: Bottle
    @State private var newPinURL: URL?
    @State private var opening: Bool = false
    private let panel = NSOpenPanel()

    var body: some View {
        VStack {
            Group {
                Image(systemName: "app.dashed")
                      .resizable()
                      .overlay {
                          Image(systemName: "plus")
                              .resizable()
                              .frame(width: 16, height: 16)
                      }
            }
            .frame(width: 45, height: 45)
            .scaleEffect(opening ? 2 : 1)
            .opacity(opening ? 0 : 1)
            Spacer()
            Text("pin.help")
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .onTapGesture(count: 1) {
            panel.canChooseFiles = true
            panel.allowedContentTypes = [UTType.exe,
                                         UTType(exportedAs: "com.microsoft.msi-installer"),
                                         UTType(exportedAs: "com.microsoft.bat")]
            panel.directoryURL = bottle.url.appending(path: "drive_c")
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false

            choosePinURL()
        }
        .sheet(item: $newPinURL) { url in
            PinCreationView(bottle: bottle, newPinURL: url)
        }
    }

    func choosePinURL() {
        withAnimation(.easeIn(duration: 0.25)) {
            opening = true
        } completion: {
            withAnimation(.easeOut(duration: 0.1)) {
                opening = false
            }
        }

        Task {
            guard await panel.runModal() == .OK,
                  let url = await panel.urls.first else { return }
            newPinURL = url
        }
    }
}
