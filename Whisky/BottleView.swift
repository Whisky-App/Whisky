//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct BottleView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            TabView {
                ConfigView(bottle: bottle)
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
                        Task(priority: .userInitiated) {
                            if result == .OK {
                                if let url = panel.urls.first {
                                    do {
                                        try await Wine.runProgram(bottle: bottle, path: url.path)
                                    } catch {
                                        print("Failed to open program at \(url.path)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle(bottle.name)
    }
}

struct ConfigView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Toggle("DXVK", isOn: $bottle.dxvk)
                    .toggleStyle(.switch)
                Toggle("Winetricks", isOn: $bottle.winetricks)
                    .toggleStyle(.switch)
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
    }
}

struct ProgramListView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Text("Installed Programs:")
                Spacer()
            }
            List {
                ForEach(bottle.programs, id: \.self) { program in
                    Text(program)
                }
            }
        }
        .padding()
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .onAppear {
            bottle.updateInstalledPrograms()
        }
    }
}

struct InfoView: View {
    @State var bottle: Bottle
    @State var wineVersion: String = ""
    @State var windowsVersion: WinVersion?

    var body: some View {
        VStack {
            HStack {
                Text("Path: \(bottle.path.path)")
                Spacer()
            }
            HStack {
                if wineVersion.isEmpty {
                    Text("Wine Version: ")
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Wine Version: ") + Text(wineVersion)
                }
                Spacer()
            }
            .padding(.vertical)
            HStack {
                if let windowsVersion = windowsVersion {
                    Text("Windows Version: ") + Text(windowsVersion.pretty())
                } else {
                    Text("Windows Version: ")
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .onAppear {
            resolveWineInfo()
        }
    }

    func resolveWineInfo() {
        Task(priority: .background) {
            do {
                try await wineVersion = Wine.wineVersion()
                try await windowsVersion = Wine.winVersion(bottle: bottle)
            } catch {
                print("Failed")
            }
        }
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        BottleView(bottle: Bottle())
            .frame(width: 500, height: 300)
    }
}
