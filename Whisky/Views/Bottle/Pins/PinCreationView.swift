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
    @State private var newPinName: String = ""
    @State private var newPinURL: URL?
    @State private var isValid: Bool = false
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
                    panel.begin { result in
                        guard result == .OK, let url = panel.urls.first else { return }
                        let oldDefaultName = (newPinURL ?? url).deletingPathExtension()
                            .lastPathComponent
                        newPinURL = url
                        // Only reset newPinName if the textbox hasn't been modified
                        if newPinName.isEmpty || newPinName == oldDefaultName {
                            newPinName = url.deletingPathExtension()
                                .lastPathComponent
                        }
                    }
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

                    let newPin = PinnedProgram(name: newPinName, url: newPinURL)

                    // Ensure this pin doesn't already exist
                    guard !bottle.settings.pins.contains(where: { pin in
                        pin.url == newPin.url
                    }) else {
                        isDuplicate = true
                        return
                    }

                    bottle.settings.pins.append(newPin)

                    // Add this program to the programs array if necessary
                    if !bottle.programs.contains(where: { program in
                        program.url == newPin.url
                    }) {
                        bottle.programs.append(Program(url: newPinURL, bottle: bottle))
                    }

                    // Trigger a reload
                    bottle.settings.pins = bottle.settings.pins
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
        .padding()
        .frame(width: 400)
    }
}
