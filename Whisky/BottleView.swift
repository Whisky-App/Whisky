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
    @State var wineVersion: String = ""
    @State var windowsVersion: WinVersion?
    @State var showBottleCreation: Bool = false

    var body: some View {
        VStack {
            HStack {
                Toggle("DXVK", isOn: $bottle.dxvk)
                    .toggleStyle(.switch)
                Toggle("Winetricks", isOn: $bottle.winetricks)
                    .toggleStyle(.switch)
                Spacer()
            }
            Divider()
            List {
                ForEach(bottle.programs, id: \.self) { program in
                    Text(program)
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
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
            HStack {
                Spacer()
                Button("Open Wine Configuration") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.cfg(bottle: bottle)
                        } catch {
                            print("Failed to launch winecfg")
                        }
                    }
                }
                Button("Open C Drive") {
                    bottle.openCDrive()
                }
                Button("Run...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe]
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showBottleCreation.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .padding()
        .navigationTitle(bottle.name)
        .onAppear {
            resolveWineInfo()
        }
        .sheet(isPresented: $showBottleCreation) {
            BottleCreationView()
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
