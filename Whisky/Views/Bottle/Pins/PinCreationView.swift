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

    @State private var newPinURL: URL?
    @State private var pinPath: String = ""
    @State private var newPinName: String = ""
    @State private var isDuplicate: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("pin.name", text: $newPinName)

                ActionView(
                    text: "pin.path",
                    subtitle: pinPath,
                    actionName: "create.browse"
                ) {
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
                        if result == .OK, let url = panel.urls.first {
                            newPinURL = url
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("pin.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("create.cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("pin.create") {
                        submit()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newPinName.isEmpty || newPinURL == nil)
                    .alert("pin.error.title", isPresented: $isDuplicate) {
                    } message: {
                        Text("pin.error.duplicate.\(newPinURL?.lastPathComponent ?? "unknown")")
                    }
                }
            }
            .onChange(of: newPinURL, initial: true) { oldValue, newValue in
                guard let newValue = newValue else { return }

                // Only reset newPinName if the textbox hasn't been modified
                if newPinName.isEmpty ||
                    newPinName == oldValue?.deletingPathExtension().lastPathComponent {

                    newPinName = newValue.deletingPathExtension().lastPathComponent
                }

                pinPath = newValue.prettyPath()
            }
            .onSubmit {
                submit()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: ViewWidth.small)
    }

    func submit() {
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
}

#Preview {
    PinCreationView(bottle: Bottle(bottleUrl: URL(filePath: "")))
}
