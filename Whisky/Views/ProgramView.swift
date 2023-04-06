//
//  ProgramView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI
import QuickLookThumbnailing

struct ProgramView: View {
    @Binding var program: Program
    @State var image: NSImage?
    @State var arguments: [String: String] = [:]

    var body: some View {
        VStack {
            Form {
                Section("info.title") {
                    HStack {
                        InfoItem(label: NSLocalizedString("info.path", comment: ""), value: program.url.path)
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
                Section("Environment Variables") {
                    ArgumentEditor(arguments: $arguments)
                }
            }
            .formStyle(.grouped)
            Spacer()
            HStack {
                Spacer()
                Button("button.showInFinder") {
                    NSWorkspace.shared.activateFileViewerSelecting([program.url])
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
            let thumbnail = QLThumbnailGenerator.Request(fileAt: program.url,
                                                         size: CGSize(width: 512, height: 512),
                                                         scale: 1,
                                                         representationTypes: .thumbnail)

            QLThumbnailGenerator.shared.generateBestRepresentation(for: thumbnail) { rep, _ in
                if let rep = rep {
                    image = rep.nsImage
                }
            }

            arguments = program.settings.settings.arguments
        }
        .onChange(of: arguments) { newValue in
            program.settings.settings.arguments = newValue
        }
    }
}

struct ArgumentEditor: View {
    @Binding var arguments: [String: String]
    @State var selection = Set<String>()

    var body: some View {
        VStack {
            List(arguments.keys.sorted(by: <), id: \.self, selection: $selection) { key in
                if let value = arguments[key] {
                    KeyItem(key: key,
                            value: value,
                            arguments: $arguments)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .cornerRadius(5)
            HStack {
                Spacer()
                Button {
                    // Need to set this in a better way cause this can break
                    arguments["VAR_\(arguments.count + 1)"] = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(ArgumentEditorButton())
                Divider()
                    .frame(height: 20)
                Button {
                    for key in selection {
                        arguments.removeValue(forKey: key)
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
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct KeyItem: View {
    @Binding var arguments: [String: String]
    @State var key: String
    @State var newKey: String
    @State var value: String
    @FocusState private var isKeyFieldFocused: Bool
    @FocusState private var isValueFieldFocused: Bool

    init(key: String, value: String, arguments: Binding<[String: String]>) {
        self._arguments = arguments
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
                    if let entry = arguments.removeValue(forKey: key) {
                        arguments[newKey] = entry
                    }
                }
            }
            Spacer()
            TextField("", text: $value)
            .textFieldStyle(.roundedBorder)
            .focused($isValueFieldFocused)
            .onChange(of: isValueFieldFocused) { focus in
                if !focus {
                    arguments[newKey] = value
                }
            }
        }
    }
}

struct ArgumentEditor_Previews: PreviewProvider {
    static var previews: some View {
        ArgumentEditor(arguments: .constant(["Test1": "Bing", "Test2": "Bong"]))
    }
}
