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
    @State var image: Image?
    @State var programLoading: Bool = false
    @AppStorage("configSectionExapnded") private var configSectionExpanded: Bool = true
    @AppStorage("envArgsSectionExpanded") private var envArgsSectionExpanded: Bool = true

    var body: some View {
        Form {
            Section("program.config", isExpanded: $configSectionExpanded) {
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
            EnvironmentArgView(program: program, isExpanded: $envArgsSectionExpanded)
        }
        .formStyle(.grouped)
        .animation(.whiskyDefault, value: configSectionExpanded)
        .animation(.whiskyDefault, value: envArgsSectionExpanded)
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
                    program.run()
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
                        icon
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
        .task {
            guard let peFile = program.peFile else { return }
            let task = Task.detached {
                guard let image = peFile.bestIcon() else { return nil as Image? }
                return Image(nsImage: image)
            }
            self.image = await task.value
        }
    }
}
