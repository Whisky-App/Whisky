//
//  ProgramView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ProgramView: View {
    @Binding var program: Program
    @State var image: NSImage?
    @State var environment: [String: String] = [:]
    @State var programLoading: Bool = false

    var body: some View {
        VStack {
            Form {
                Section("info.title") {
                    HStack {
                        InfoItem(label: String(localized: "info.path"), value: program.url.prettyPath())
                        .contextMenu {
                            Button {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(program.url.path, forType: .string)
                            } label: {
                                Text("info.path.copy")
                            }
                        }
                    }
                }
                Section("program.config") {
                    VStack {
                        HStack {
                            Text("program.args")
                            Spacer()
                        }
                        TextField("", text: $program.settings.arguments)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .labelsHidden()
                    }
                    EnvironmentVarEditor(environment: $environment)
                }
            }
            .formStyle(.grouped)
            Spacer()
            HStack {
                Spacer()
                Button("button.showInFinder") {
                    NSWorkspace.shared.activateFileViewerSelecting([program.url])
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
            do {
                let peFile = try PEFile(data: Data(contentsOf: program.url))
                var icons: [NSImage] = []
                if let resourceSection = peFile.resourceSection {
                    for entries in resourceSection.allEntries where entries.icon.isValid {
                        icons.append(entries.icon)
                    }
                } else {
                    print("No resource section")
                    return
                }

                if icons.count > 0 {
                    image = icons[0]
                }
            } catch {
                print(error)
            }

            environment = program.settings.environment
        }
        .onChange(of: environment) { newValue in
            program.settings.environment = newValue
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
            TextField("", text: $newKey)
            .textFieldStyle(.roundedBorder)
            .onChange(of: newKey) { _ in
                newKey = String(newKey.filter { !$0.isWhitespace })
            }
            .focused($isKeyFieldFocused)
            .onChange(of: isKeyFieldFocused) { focus in
                if !focus {
                    if let entry = environment.removeValue(forKey: key) {
                        environment[newKey] = entry
                    }
                }
            }
            Spacer()
            TextField("", text: $value)
            .textFieldStyle(.roundedBorder)
            .focused($isValueFieldFocused)
            .onChange(of: isValueFieldFocused) { focus in
                if !focus {
                    environment[newKey] = value
                }
            }
        }
    }
}

// swiftlint:disable line_length
struct ProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramView(program: .constant(Program(name: "MinecraftLauncher.exe",
                                               url: URL(filePath: "/Users/isaacmarovitz/Library/Containers/com.isaacmarovitz.Whisky/Bottles/Windows 10/drive_c/Program Files (x86)/Minecraft Launcher/MinecraftLauncher.exe"),
                                               bottle: Bottle())))
    }
}
// swiftlint:enable line_length
