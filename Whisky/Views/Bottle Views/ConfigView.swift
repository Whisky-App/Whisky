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
    @State var canChangeWinVersion: Bool = true

    init(bottle: Binding<Bottle>) {
        self._bottle = bottle
        self.windowsVersion = bottle.settings.windowsVersion.wrappedValue
        self.canChangeWinVersion = true
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
                }
                Section("config.title.metal") {
                    Toggle(isOn: $bottle.settings.metalHud) {
                        Text("config.metalHud")
                    }
                    Toggle(isOn: $bottle.settings.metalTrace) {
                        Text("config.metalTrace")
                        Text("config.metalTrace.info")
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
            .onChange(of: windowsVersion) { _, newValue in
                canChangeWinVersion = false
                Task(priority: .userInitiated) {
                    do {
                        try await Wine.changeWinVersion(bottle: bottle, win: newValue)
                        canChangeWinVersion = true
                        bottle.settings.windowsVersion = newValue
                    } catch {
                        print(error)
                        canChangeWinVersion = true
                        windowsVersion = bottle.settings.windowsVersion
                    }
                }
            }
            .onAppear {
                windowsVersion = bottle.settings.windowsVersion
            }
        }
        .navigationTitle(String(format: NSLocalizedString("tab.navTitle.config",
                                                          comment: ""),
                                bottle.name))
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(bottle: .constant(Bottle()))
    }
}
