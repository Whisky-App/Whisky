//
//  SettingsView.swift
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

struct SettingsView: View {
    @AppStorage("SUEnableAutomaticChecks") var whiskyUpdate = true
    @AppStorage("killOnTerminate") var killOnTerminate = true
    @AppStorage("checkGPTKUpdates") var checkGPTKUpdates = true
    @AppStorage("defaultBottleLocation") var defaultBottleLocation = BottleData.defaultBottleDir

    @State private var bottlePath: String = ""

    var body: some View {
        Form {
            Section("settings.general") {
                Toggle("settings.toggle.kill.on.terminate", isOn: $killOnTerminate)
                HStack {
                    VStack(alignment: .leading) {
                        Text("settings.path")
                            .foregroundStyle(.primary)
                        Text(bottlePath)
                            .foregroundStyle(.secondary)
                            .truncationMode(.middle)
                            .lineLimit(2)
                            .help(bottlePath)
                    }

                    Spacer()
                    Button {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.canCreateDirectories = true
                        panel.directoryURL = BottleData.containerDir
                        panel.begin { result in
                            if result == .OK {
                                if let url = panel.urls.first {
                                    defaultBottleLocation = url
                                }
                            }
                        }
                    } label: {
                        Text("create.browse")
                    }
                }
            }
            Section("settings.updates") {
                Toggle("settings.toggle.whisky.updates", isOn: $whiskyUpdate)
                Toggle("settings.toggle.gptk.updates", isOn: $checkGPTKUpdates)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 250)
        .onChange(of: defaultBottleLocation) {
            bottlePath = defaultBottleLocation.prettyPath()
        }
        .onAppear {
            bottlePath = defaultBottleLocation.prettyPath()
        }
    }
}

#Preview {
    SettingsView()
}
