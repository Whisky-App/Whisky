//
//  ConfigView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ConfigView: View {
    @Binding var bottle: Bottle
    @State var windowsVersion: WinVersion
    @State var buildVersion: String = ""
    @State var canChangeWinVersion: Bool = true
    @State var canChangeBuildVersion: Bool = false
    @State var winVersionLoaded: Bool = false
    @State var retinaMode: Bool = false
    @State var canChangeRetinaMode: Bool = false

    init(bottle: Binding<Bottle>) {
        self._bottle = bottle
        self.windowsVersion = bottle.settings.windowsVersion.wrappedValue
    }

    var body: some View {
        VStack {
            Form {
                Section {
                    Picker("config.winVersion",
                           selection: $windowsVersion) {
                        ForEach(WinVersion.allCases.reversed(), id: \.self) {
                            Text($0.pretty())
                        }
                    }
                    .disabled(!canChangeWinVersion)
                    if !canChangeBuildVersion {
                        HStack {
                            Text("config.buildVersion")
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                        }
                    } else {
                        TextField("config.buildVersion", text: $buildVersion)
                            .onSubmit {
                                canChangeBuildVersion = false
                                Task(priority: .userInitiated) {
                                    if let version = Int(buildVersion) {
                                        do {
                                            try await Wine.changeBuildVersion(bottle: bottle, version: version)
                                        } catch {
                                            print("Failed to change build version")
                                        }
                                    }
                                    canChangeBuildVersion = true
                                }
                            }
                    }
                }
                Section("config.title.metal") {
                    Toggle(isOn: $bottle.settings.metalHud) {
                        Text("config.metalHud")
                    }
                    Toggle(isOn: $bottle.settings.metalTrace) {
                        Text("config.metalTrace")
                        Text("config.metalTrace.info")
                    }
                    if canChangeRetinaMode {
                        Toggle(isOn: $retinaMode) {
                            Text("config.retinaMode")
                        }
                        .onChange(of: retinaMode) { _ in
                            Task(priority: .userInitiated) {
                                await Wine.changeRetinaMode(bottle: bottle, retinaMode: retinaMode)
                            }
                        }
                    } else {
                        HStack {
                            Text("config.retinaMode")
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                        }
                    }
                }
                Section {
                    Toggle(isOn: $bottle.settings.esync) {
                        Text("config.esync")
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("config.controlPanel") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.control(bottle: bottle)
                        } catch {
                            print("Failed to launch control")
                        }
                    }
                }
                Button("config.regedit") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.regedit(bottle: bottle)
                        } catch {
                            print("Failed to launch regedit")
                        }
                    }
                }
                Button("config.winecfg") {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.cfg(bottle: bottle)
                        } catch {
                            print("Failed to launch winecfg")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String(format: String(localized: "tab.navTitle.config"),
                                bottle.settings.name))
        .onAppear {
            windowsVersion = bottle.settings.windowsVersion
            winVersionLoaded = true

            Task(priority: .background) {
                do {
                    buildVersion = try await Wine.buildVersion(bottle: bottle)
                    canChangeBuildVersion = true
                } catch {
                    print(error)
                }
            }
            Task(priority: .background) { @MainActor in
                retinaMode = await Wine.retinaMode(bottle: bottle)
                canChangeRetinaMode = true
            }
        }
        .onChange(of: windowsVersion) { newValue in
            if winVersionLoaded {
                canChangeWinVersion = false
                canChangeBuildVersion = false
                Task(priority: .userInitiated) {
                    do {
                        try await Wine.changeWinVersion(bottle: bottle, win: newValue)
                        canChangeWinVersion = true
                        bottle.settings.windowsVersion = newValue
                        buildVersion = try await Wine.buildVersion(bottle: bottle)
                        canChangeBuildVersion = true
                    } catch {
                        print(error)
                        canChangeWinVersion = true
                        canChangeBuildVersion = true
                        windowsVersion = bottle.settings.windowsVersion
                    }
                }
            }
        }
        .onChange(of: buildVersion) { _ in
            // Remove anything that isn't a number
            buildVersion = buildVersion.filter("0123456789".contains)
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(bottle: .constant(Bottle()))
    }
}
