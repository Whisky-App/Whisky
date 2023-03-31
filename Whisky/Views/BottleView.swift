//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct BottleView: View {
    @Binding var bottle: Bottle
    @State var programLoading: Bool = false

    var body: some View {
        VStack {
            TabView {
                ConfigView(bottle: $bottle)
                    .tabItem {
                        Text("Config")
                    }
                ProgramListView(bottle: bottle)
                    .tabItem {
                        Text("Programs")
                    }
                InfoView(bottle: bottle)
                    .tabItem {
                        Text("Info")
                    }
            }
            Spacer()
            HStack {
                Spacer()
                Button("Open C Drive") {
                    bottle.openCDrive()
                }
                Button("Run...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe,
                                                 UTType(importedAs: "com.microsoft.msi-installer")]
                    panel.begin { result in
                        programLoading = true
                        Task(priority: .userInitiated) {
                            if result == .OK {
                                if let url = panel.urls.first {
                                    do {
                                        try await Wine.runProgram(bottle: bottle, path: url.path)
                                        programLoading = false
                                    } catch {
                                        programLoading = false
                                        let alert = NSAlert()
                                        alert.messageText = "Failed to open program!"
                                        alert.informativeText = "Failed to open \(url.lastPathComponent)"
                                        alert.alertStyle = .critical
                                        alert.addButton(withTitle: "OK")
                                        alert.runModal()
                                    }
                                }
                            }
                        }
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
        }
        .padding()
        .navigationTitle(bottle.name)
    }
}

struct ConfigView: View {
    @Binding var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Toggle("DXVK", isOn: $bottle.settings.settings.dxvk)
                    .toggleStyle(.switch)
                    .onChange(of: bottle.settings.settings.dxvk) { enabled in
                        if enabled {
                            print("Enabling DXVK")
                            bottle.enableDXVK()
                        } else {
                            print("Disabling DXVK")
                            bottle.disableDXVK()
                        }
                    }
                Toggle("DXVK HUD", isOn: $bottle.settings.settings.dxvkHud)
                    .toggleStyle(.switch)
                    .disabled(!bottle.settings.settings.dxvk)
                Spacer()
            }
            Spacer()
                .frame(height: 20)
            HStack {
                Button("Open Wine Configuration") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.cfg(bottle: bottle)
                        } catch {
                            print("Failed to launch winecfg")
                        }
                    }
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .onAppear {
            bottle.enableDXVK()
        }
    }
}

struct ProgramListView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Text("Installed Programs")
                Spacer()
                Button(action: {
                    bottle.updateInstalledPrograms()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                })
                .buttonStyle(.bordered)
            }
            List {
                ForEach(bottle.programs, id: \.self) { program in
                    HStack {
                        Text(program.lastPathComponent)
                        Spacer()
                        Button(action: {
                        }, label: {
                            Image(systemName: "ellipsis.circle.fill")
                        })
                        .buttonStyle(.plain)
                        Button(action: {
                            Task(priority: .userInitiated) {
                                do {
                                    try await Wine.runProgram(bottle: bottle,
                                                              path: program.path)
                                } catch {
                                    let alert = NSAlert()
                                    alert.messageText = "Failed to open program!"
                                    alert.informativeText = "Failed to open \(program.lastPathComponent)"
                                    alert.alertStyle = .critical
                                    alert.addButton(withTitle: "OK")
                                    alert.runModal()
                                }
                            }
                        }, label: {
                            Image(systemName: "play.circle.fill")
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
            .cornerRadius(5)
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .onAppear {
                bottle.updateInstalledPrograms()
            }
        }
        .padding()
    }
}

struct InfoView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Text("Path: \(bottle.url.path)")
                Spacer()
            }
            HStack {
                Text("Wine Version: \(bottle.settings.settings.wineVersion)")
                Spacer()
            }
            .padding(.vertical)
            HStack {
                Text("Windows Version: \(bottle.settings.settings.windowsVersion.pretty())")
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        BottleView(bottle: .constant(Bottle()))
            .frame(width: 500, height: 300)
    }
}
