//
//  ProgramView.swift
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
import UniformTypeIdentifiers

struct ProgramView: View {
    @Binding var program: Program
    @State var image: NSImage?
    @State var environment: [String: String] = [:]
    @State var programLoading: Bool = false
    @State var locale: Locales = .auto

    var body: some View {
        Form {
            Section("program.config") {
                Picker("locale.title", selection: $locale) {
                    ForEach(Locales.allCases, id: \.self) {
                        Text($0.pretty())
                    }
                }
                VStack {
                    HStack {
                        Text("program.args")
                        Spacer()
                    }
                    TextField(String(), text: $program.settings.arguments)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .labelsHidden()
                }
                EnvironmentVarEditor(environment: $environment)
            }
        }
        .formStyle(.grouped)
        .bottomBar {
            HStack {
                Spacer()
                Button("button.showInFinder") {
                    NSWorkspace.shared.activateFileViewerSelecting([program.url])
                }
                Button("button.createShortcut") {
                    let panel = NSSavePanel()
                    let applicationDir = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)[0]
                    let name = program.name.replacingOccurrences(of: ".exe", with: "")
                    panel.directoryURL = applicationDir
                    panel.canCreateDirectories = true
                    panel.allowedContentTypes = [UTType.applicationBundle]
                    panel.allowsOtherFileTypes = false
                    panel.isExtensionHidden = true
                    panel.nameFieldStringValue = name + ".app"
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.url {
                                let name = url.deletingPathExtension().lastPathComponent
                                Task(priority: .userInitiated) {
                                    await ProgramShortcut.createShortcut(program, app: url, name: name)
                                }
                            }
                        }
                    }
                }
                Button("button.run") {
                    programLoading = true
                    Task(priority: .userInitiated) {
                        await program.run()
                        programLoading = false
                    }
                }
                .disabled(programLoading)
                if programLoading {
                    Spacer()
                        .frame(width: 10)
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding()
        }
        .navigationTitle(program.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Group {
                    if let icon = image {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 25, height: 25)
                    } else {
                        Image(systemName: "app.dashed")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                }
                .padding(.trailing, 5)
            }
        }
        .onAppear {
            if let peFile = program.peFile {
                image = peFile.bestIcon()
            }

            environment = program.settings.environment
            locale = program.settings.locale
        }
        .onChange(of: environment) { _, newValue in
            program.settings.environment = newValue
        }
        .onChange(of: locale) { _, newValue in
            program.settings.locale = newValue
        }
    }
}

struct EnvironmentVarEditor: View {
    @Binding var environment: [String: String]
    @State var selection = Set<String>()

    var body: some View {
        VStack {
            HStack {
                Text("program.env")
                Spacer()
            }
            List(environment.keys.sorted(by: <), id: \.self, selection: $selection) { key in
                if let value = environment[key] {
                    KeyItem(key: key,
                            value: value,
                            environment: $environment)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .cornerRadius(5)
            HStack {
                Spacer()
                Button {
                    // Need to set this in a better way cause this can break
                    environment["VAR_\(environment.count + 1)"] = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(ArgumentEditorButton())
                Divider()
                    .frame(height: 20)
                Button {
                    for key in selection {
                        environment.removeValue(forKey: key)
                    }
                    selection.removeAll()
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(ArgumentEditorButton())
            }
        }
    }
}

struct ArgumentEditorButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 15, height: 15)
            .padding(4)
            // Without this the selectable area is reduced to just
            // the icons which isn't great
            .background(Color(nsColor: NSColor.windowBackgroundColor)
                .opacity(0.001))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct KeyItem: View {
    @Binding var environment: [String: String]
    let key: String
    @State var newKey: String
    @State var value: String
    @FocusState private var isKeyFieldFocused: Bool
    @FocusState private var isValueFieldFocused: Bool

    init(key: String, value: String, environment: Binding<[String: String]>) {
        self._environment = environment
        self.key = key
        self.newKey = key
        self.value = value
    }

    var body: some View {
        HStack {
            TextField(String(), text: $newKey)
            .textFieldStyle(.roundedBorder)
            .onChange(of: newKey) {
                newKey = String(newKey.filter { !$0.isWhitespace })
            }
            .focused($isKeyFieldFocused)
            .onChange(of: isKeyFieldFocused) { _, focus in
                if !focus {
                    if let entry = environment.removeValue(forKey: key) {
                        environment[newKey] = entry
                    }
                }
            }
            Spacer()
            TextField(String(), text: $value)
            .textFieldStyle(.roundedBorder)
            .focused($isValueFieldFocused)
            .onChange(of: isValueFieldFocused) { _, focus in
                if !focus {
                    environment[newKey] = value
                }
            }
        }
    }
}
