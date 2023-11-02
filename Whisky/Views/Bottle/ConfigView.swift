//
//  ConfigView.swift
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

enum LoadingState {
    case loading
    case modifying
    case success
    case failed
}

struct ConfigView: View {
    @Binding var bottle: Bottle
    @State private var buildVersion: Int = 0
    @State private var retinaMode: Bool = false
    @State private var dpiConfig: Int = 96
    @State private var winVersionLoadingState: LoadingState = .loading
    @State private var buildVersionLoadingState: LoadingState = .loading
    @State private var retinaModeLoadingState: LoadingState = .loading
    @State private var dpiConfigLoadingState: LoadingState = .loading
    @State private var dpiSheetPresented: Bool = false
    @AppStorage("wineSectionExpanded") private var wineSectionExpanded: Bool = true
    @AppStorage("dxvkSectionExpanded") private var dxvkSectionExpanded: Bool = true
    @AppStorage("metalSectionExpanded") private var metalSectionExpanded: Bool = true

    var body: some View {
        Form {
            Section("config.title.wine", isExpanded: $wineSectionExpanded) {
                SettingItemView(title: "config.winVersion", loadingState: $winVersionLoadingState) {
                    Picker("config.winVersion", selection: $bottle.settings.windowsVersion) {
                        ForEach(WinVersion.allCases.reversed(), id: \.self) {
                            Text($0.pretty())
                        }
                    }
                }
                SettingItemView(title: "config.buildVersion", loadingState: $buildVersionLoadingState) {
                    TextField("config.buildVersion", value: $buildVersion, formatter: NumberFormatter())
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            buildVersionLoadingState = .modifying
                            Task(priority: .userInitiated) {
                                do {
                                    try await Wine.changeBuildVersion(bottle: bottle, version: buildVersion)
                                    buildVersionLoadingState = .success
                                } catch {
                                    print("Failed to change build version")
                                    buildVersionLoadingState = .failed
                                }
                            }
                        }
                }
                SettingItemView(title: "config.retinaMode", loadingState: $retinaModeLoadingState) {
                    Toggle("config.retinaMode", isOn: $retinaMode)
                        .onChange(of: retinaMode, { _, newValue in
                            Task(priority: .userInitiated) {
                                retinaModeLoadingState = .modifying
                                do {
                                    try await Wine.changeRetinaMode(bottle: bottle, retinaMode: newValue)
                                    retinaModeLoadingState = .success
                                } catch {
                                    print("Failed to change build version")
                                    retinaModeLoadingState = .failed
                                }
                            }
                        })
                }
                Picker("config.enhancedSync", selection: $bottle.settings.enhancedSync) {
                    Text("config.enhancedSync.none").tag(EnhancedSync.none)
                    Text("config.enhacnedSync.esync").tag(EnhancedSync.esync)
                    Text("config.enhacnedSync.msync").tag(EnhancedSync.msync)
                }
                SettingItemView(title: "config.dpi", loadingState: $dpiConfigLoadingState) {
                    Button("config.inspect") {
                        dpiSheetPresented = true
                    }
                    .sheet(isPresented: $dpiSheetPresented) {
                        DPIConfigSheetView(
                            dpiConfig: $dpiConfig,
                            isRetinaMode: $retinaMode,
                            presented: $dpiSheetPresented
                        )
                    }
                }
            }
            Section("config.title.dxvk", isExpanded: $dxvkSectionExpanded) {
                Toggle(isOn: $bottle.settings.dxvk) {
                    Text("config.dxvk")
                }
                Toggle(isOn: $bottle.settings.dxvkAsync) {
                    Text("config.dxvk.async")
                }
                .disabled(!bottle.settings.dxvk)
                Picker("config.dxvkHud", selection: $bottle.settings.dxvkHud) {
                    Text("config.dxvkHud.full").tag(DXVKHUD.full)
                    Text("config.dxvkHud.partial").tag(DXVKHUD.partial)
                    Text("config.dxvkHud.fps").tag(DXVKHUD.fps)
                    Text("config.dxvkHud.off").tag(DXVKHUD.off)
                }
                .disabled(!bottle.settings.dxvk)
            }
            Section("config.title.metal", isExpanded: $metalSectionExpanded) {
                Toggle(isOn: $bottle.settings.metalHud) {
                    Text("config.metalHud")
                }
                Toggle(isOn: $bottle.settings.metalTrace) {
                    Text("config.metalTrace")
                    Text("config.metalTrace.info")
                }
            }
        }
        .formStyle(.grouped)
        .animation(.easeInOut(duration: 0.2), value: wineSectionExpanded)
        .animation(.easeInOut(duration: 0.2), value: dxvkSectionExpanded)
        .animation(.easeInOut(duration: 0.2), value: metalSectionExpanded)
        .bottomBar {
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
        .navigationTitle("tab.config")
        .onAppear {
            winVersionLoadingState = .success

            loadBuildName()

            Task(priority: .userInitiated) {
                do {
                    retinaMode = try await Wine.retinaMode(bottle: bottle)
                    retinaModeLoadingState = .success
                } catch {
                    print(error)
                    retinaModeLoadingState = .failed
                }
            }
            Task(priority: .userInitiated) {
                do {
                    dpiConfig = try await Wine.dpiResolution(bottle: bottle)
                    dpiConfigLoadingState = .success
                } catch {
                    print(error)
                    // If DPI has not yet been edited, there will be no registry entry
                    dpiConfigLoadingState = .success
                }
            }
        }
        .onChange(of: bottle.settings.windowsVersion) { _, newValue in
            if winVersionLoadingState == .success {
                winVersionLoadingState = .loading
                buildVersionLoadingState = .loading
                Task(priority: .userInitiated) {
                    do {
                        try await Wine.changeWinVersion(bottle: bottle, win: newValue)
                        winVersionLoadingState = .success
                        bottle.settings.windowsVersion = newValue
                        loadBuildName()
                    } catch {
                        print(error)
                        winVersionLoadingState = .failed
                    }
                }
            }
        }
        .onChange(of: dpiConfig) {
            if dpiConfigLoadingState == .success {
                Task(priority: .userInitiated) {
                    dpiConfigLoadingState = .modifying
                    do {
                        try await Wine.changeDpiResolution(bottle: bottle, dpi: dpiConfig)
                        dpiConfigLoadingState = .success
                    } catch {
                        print(error)
                        dpiConfigLoadingState = .failed
                    }
                }
            }
        }
    }

    func loadBuildName() {
        Task(priority: .userInitiated) {
            do {
                let buildVersionString = try await Wine.buildVersion(bottle: bottle)
                buildVersion = Int(buildVersionString) ?? 0
                buildVersionLoadingState = .success
            } catch {
                print(error)
                buildVersionLoadingState = .failed
            }
        }
    }
}

struct DPIConfigSheetView: View {
    @Binding var dpiConfig: Int
    @Binding var isRetinaMode: Bool
    @Binding var presented: Bool
    @State var stagedChanges: Float
    @FocusState var textFocused: Bool

    init(dpiConfig: Binding<Int>, isRetinaMode: Binding<Bool>, presented: Binding<Bool>) {
        self._dpiConfig = dpiConfig
        self._isRetinaMode = isRetinaMode
        self._presented = presented
        self.stagedChanges = Float(dpiConfig.wrappedValue)
    }

    var body: some View {
        VStack {
            HStack {
                Text("configDpi.title")
                    .fontWeight(.bold)
                Spacer()
            }
            Divider()
            GroupBox(label: Label("configDpi.preview", systemImage: "text.magnifyingglass")) {
                VStack {
                    HStack {
                        Text("configDpi.previewText")
                            .padding(16)
                            .font(.system(size:
                                (10 * CGFloat(stagedChanges)) / 72 *
                                          (isRetinaMode ? 0.5 : 1)
                            ))
                        Spacer()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 80)
            }
            HStack {
                Slider(value: $stagedChanges, in: 96...480, step: 24, onEditingChanged: { _ in
                    textFocused = false
                })
                TextField(String(), value: $stagedChanges, format: .number)
                    .frame(width: 40)
                    .focused($textFocused)
                Text("configDpi.dpi")
            }
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    presented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("button.ok") {
                    dpiConfig = Int(stagedChanges)
                    presented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 240)
    }
}

struct SettingItemView<V: View>: View {
    var title: String.LocalizationValue
    @Binding var loadingState: LoadingState
    @ViewBuilder var content: () -> V

    @Namespace private var viewId
    @Namespace private var progressViewId

    var body: some View {
        ZStack {
            if loadingState == .failed {
                HStack {
                    Text(String(localized: title))
                    Spacer()
                    Text("config.notAvailable").opacity(0.5)
                }
            } else if loadingState == .loading {
                HStack {
                    Text(String(localized: title))
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .matchedGeometryEffect(id: progressViewId, in: viewId)
                }
            } else {
                HStack(spacing: 16) {
                    Text(String(localized: title))
                    Spacer()
                    if loadingState == .modifying {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .matchedGeometryEffect(id: progressViewId, in: viewId)
                    }
                    content()
                        .labelsHidden()
                        .disabled(loadingState == .modifying)
                }
            }
        }
        .animation(.default, value: loadingState)
    }
}
