//
//  ConfigView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

enum LoadingState {
    case loading
    case modifying
    case success
    case failed
}

struct ConfigView: View {
    @Binding var bottle: Bottle
    @State var windowsVersion: WinVersion
    @State var displayBuildVersion: String = ""
    @State var buildVersion: String = ""
    @State var retinaMode: Bool = false
    @State var winVersionLoadingState: LoadingState = LoadingState.loading
    @State var buildVersionLoadingState: LoadingState = LoadingState.loading
    @State var retinaModeLoadingState: LoadingState = LoadingState.loading

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
                   .disabled(winVersionLoadingState != LoadingState.success)
                    if buildVersionLoadingState == LoadingState.failed {
                        HStack {
                            Text("config.buildVersion")
                            Spacer()
                            Text("config.notAvailable").opacity(0.5)
                        }
                    } else if buildVersionLoadingState == LoadingState.loading {
                        HStack {
                            Text("config.buildVersion")
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                        }
                    } else {
                        TextField("config.buildVersion", text: $displayBuildVersion)
                            .onSubmit {
                                buildVersionLoadingState = LoadingState.modifying
                                Task(priority: .userInitiated) {
                                    if let version = Int(displayBuildVersion) {
                                        do {
                                            try await Wine.changeBuildVersion(bottle: bottle, version: version)
                                        } catch {
                                            print("Failed to change build version")
                                        }
                                    } else {
                                        displayBuildVersion = buildVersion
                                    }
                                    buildVersionLoadingState = LoadingState.success
                                }
                            }.disabled(buildVersionLoadingState == LoadingState.modifying)
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
                    if retinaModeLoadingState != LoadingState.loading {
                        Toggle(isOn: $retinaMode) {
                            Text("config.retinaMode")
                        }
                        .onChange(of: retinaMode) { _ in
                            Task(priority: .userInitiated) {
                                retinaModeLoadingState = LoadingState.modifying
                                do {
                                    try await Wine.changeRetinaMode(bottle: bottle, retinaMode: retinaMode)
                                } catch {
                                    print("Failed to change build version")
                                }
                                retinaModeLoadingState = LoadingState.success
                            }
                        }.disabled(
                            retinaModeLoadingState == LoadingState.failed ||
                            retinaModeLoadingState == LoadingState.modifying
                        )
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
                                bottle.name))
        .onAppear {
            windowsVersion = bottle.settings.windowsVersion
            winVersionLoadingState = LoadingState.success

            loadBuildName()

            Task(priority: .background) {
                do {
                    retinaMode = try await Wine.retinaMode(bottle: bottle)
                    retinaModeLoadingState = LoadingState.success
                } catch {
                    print(error)
                    retinaModeLoadingState = LoadingState.failed
                }
            }
        }
        .onChange(of: windowsVersion) { newValue in
            if winVersionLoadingState == LoadingState.success {
                winVersionLoadingState = LoadingState.loading
                buildVersionLoadingState = LoadingState.loading
                Task(priority: .userInitiated) {
                    do {
                        try await Wine.changeWinVersion(bottle: bottle, win: newValue)
                        winVersionLoadingState = LoadingState.success
                        bottle.settings.windowsVersion = newValue
                        loadBuildName()
                    } catch {
                        print(error)
                        winVersionLoadingState = LoadingState.failed
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

    func loadBuildName() {
        Task(priority: .background) {
            do {
                buildVersion = try await Wine.buildVersion(bottle: bottle)
                displayBuildVersion = buildVersion
                buildVersionLoadingState = LoadingState.success
            } catch {
                print(error)
                buildVersionLoadingState = LoadingState.failed
            }
        }
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(bottle: .constant(Bottle()))
    }
}
