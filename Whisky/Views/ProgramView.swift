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
    @ObservedObject var program: Program
    @State var image: NSImage?
    @State var programLoading: Bool = false

    private var environmentKeys: [String] {
        return program.settings.environment.keys.sorted(by: <)
    }

    var body: some View {
        Form {
            Section("program.config") {
                Picker("locale.title", selection: $program.settings.locale) {
                    ForEach(Locales.allCases, id: \.self) { locale in
                        Text(locale.pretty()).id(locale)
                    }
                }
                VStack {
                    HStack {
                        Text("program.args")
                        Spacer()
                    }
                    TextField("program.args", text: $program.settings.arguments)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .labelsHidden()
                }
            }

            Section {
                ForEach(environmentKeys, id: \.self) { key in
                    KeyItem(key: key, program: program)
                }
            } header: {
                HStack {
                    Text("program.env").frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Button("environment.add", systemImage: "plus", action: {
                        program.settings.environment["VAR_\(program.settings.environment.count + 1)"] = ""
                    })
                    .buttonStyle(.plain)
                    .labelStyle(.titleAndIcon)
                }
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
        }
    }
}

struct KeyItem: View {
    enum FocusedField: Hashable {
        case key, value
    }

    @ObservedObject private var program: Program
    @State private var key: String
    @State private var newKey: String
    @State private var value: String
    @FocusState private var focus: FocusedField?

    init(key: String, program: Program) {
        self.program = program
        self.key = key
        self.newKey = key
        self.value = program.settings.environment[key] ?? ""
    }

    var body: some View {
        HStack {
            TextField(String(), text: $newKey)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(maxHeight: .infinity)
                .focused($focus, equals: FocusedField.key)
                .onChange(of: newKey) {
                    newKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .onSubmit {
                    updateKey(from: newKey)
                }
            TextField(String(), text: $value)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(maxHeight: .infinity)
                .focused($focus, equals: FocusedField.value)
                .onSubmit {
                    program.settings.environment[key] = value
                }

            Button("environment.remove", systemImage: "trash") {
                program.settings.environment.removeValue(forKey: key)
            }.buttonStyle(.plain).labelStyle(.iconOnly)
        }.onChange(of: focus) { oldValue, _ in
            switch oldValue {
            case .key:
                updateKey(from: newKey)
            case .value:
                program.settings.environment[key] = value
            case nil:
                break
            }
        }
    }

    /// Update the key on the environment
    private func updateKey(from newKey: String) {
        let newKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key != newKey else { return }
        program.settings.environment.removeValue(forKey: key)
        guard !newKey.isEmpty else { return }
        program.settings.environment[newKey] = value
        self.key = newKey
    }
}
