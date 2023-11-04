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
    var bottle: Bottle
    @State var newPinName: String = ""
    @State var newPinURL: URL = BottleData.defaultBottleDir
    @State var pinPath: String = ""
    @State var nameValid: Bool = false
    @State var didError: Bool = false
    @State var errorMessage: String = ""
    @Binding var loadStartMenu: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("pin.create.title")
                    .bold()
                Spacer()
            }
            Divider()
            HStack(alignment: .top) {
                Text("pin.create.name")
                Spacer()
                TextField(String(), text: $newPinName)
                    .frame(width: 180)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: newPinName) { _, name in
                        nameValid = !name.isEmpty
                    }
            }
            HStack {
                Text("pin.create.path")
                Spacer()
                Button("create.browse") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe,
                                                 UTType(exportedAs: "com.microsoft.msi-installer"),
                                                 UTType(exportedAs: "com.microsoft.bat")]
                    panel.directoryURL = bottle.url.appending(path: "drive_c")
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                newPinURL = url
                            }
                        }
                    }
                }
            }
            HStack {
                Text(pinPath)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .help(pinPath)
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("pin.create") {
                    let newlyCreatedPin = Program(name: newPinName, url: newPinURL, bottle: bottle)
                    let existingProgram = bottle.programs.first(where: { program in
                        program.url == newlyCreatedPin.url
                    })
                    // Ensure this URL isn't already pinned
                    errorMessage = String(localized: "pin.error.duplicate")
                    didError = existingProgram != nil && existingProgram?.pinned ?? false
                    if !didError {
                        // Only continue if a pinned duplicate doesn't exist
                        errorMessage = String(localized: "pin.error.create")
                        // If this is a new program, add it to the array
                        if existingProgram != nil {
                            bottle.programs.append(newlyCreatedPin)
                        }
                        didError = !newlyCreatedPin.togglePinned()
                        if !didError {
                            loadStartMenu.toggle()
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!nameValid)
                .alert(String(localized: "pin.error.title"),
                    isPresented: $didError
                ) {
                    Button("button.ok") {
                    }
                } message: {
                    Text(errorMessage)
                }
            }
        }
        .padding()
        .onChange(of: newPinURL) {
            pinPath = newPinURL.prettyPath()
            if newPinName.isEmpty {
                newPinName = newPinURL.lastPathComponent
                                        .replacingOccurrences(of: ".exe", with: "")
            }
        }
        .onAppear {
            pinPath = bottle.url
                .appending(path: "drive_c")
                .prettyPath()
        }
        .frame(width: 400, height: 180)
    }
}
