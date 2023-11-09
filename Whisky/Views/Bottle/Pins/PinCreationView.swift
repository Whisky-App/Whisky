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
    @State private var newPinURL: URL = BottleData.defaultBottleDir
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
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                TextField(String(), text: $newPinName)
                    .frame(width: 180)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("pin.path")
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                Button("create.browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe,
                                                 UTType(exportedAs: "com.microsoft.msi-installer"),
                                                 UTType(exportedAs: "com.microsoft.bat")]
                    panel.directoryURL = newPinURL
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                let oldUrl = newPinURL.lastPathComponent
                                                      .replacingOccurrences(of: ".exe", with: "")
                                                      .replacingOccurrences(of: ".msi", with: "")
                                                      .replacingOccurrences(of: ".bat", with: "")
                                newPinURL = url
                                // Only reset newPinName if the textbox hasn't been modified
                                if newPinName.isEmpty || newPinName == oldUrl {
                                    newPinName = url.lastPathComponent
                                                    .replacingOccurrences(of: ".exe", with: "")
                                                    .replacingOccurrences(of: ".msi", with: "")
                                                    .replacingOccurrences(of: ".bat", with: "")
                                }
                            }
                        }
                    }
                }
            }
            let pinPath = newPinURL.prettyPath()
            Text(pinPath)
                .truncationMode(.middle)
                .lineLimit(2, reservesSpace: true)
                .help(pinPath)
            HStack {
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .frame(maxWidth: .infinity, alignment: .trailing)
                Button("pin.create") {
                    let newlyCreatedPin = Program(name: newPinName, url: newPinURL, bottle: bottle)
                    let existingProgram = bottle.programs.first(where: { program in
                        program.url == newlyCreatedPin.url
                    })
                    // Ensure this URL isn't already pinned
                    isDuplicate = existingProgram != nil && existingProgram?.pinned ?? false
                    if !isDuplicate {
                        // If this is a new program, add it to the array
                        if existingProgram != nil {
                            bottle.programs.append(newlyCreatedPin)
                        }
                        newlyCreatedPin.pinned = true
                        // Trigger a reload
                        bottle.settings.pins = bottle.settings.pins
                        bottle.updateInstalledPrograms()
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newPinName.isEmpty || newPinURL == bottle.url.appending(path: "drive_c"))
                .alert(String(localized: "pin.error.title"),
                    isPresented: $isDuplicate
                ) {}
                message: {
                    Text(String(format: String(localized: "pin.error.duplicate"),
                                newPinURL.lastPathComponent))
                }
            }
        }
        .padding()
        .onAppear {
            // Ensure newPinURL is initialized to a valid URL
            newPinURL = bottle.url.appending(path: "drive_c")
        }
        .frame(width: 400)
    }
}
