//
//  ConfigView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ConfigView: View {
    @Binding var bottle: Bottle

    var body: some View {
        VStack {
            Form {
                Section("config.title.dxvk") {
                    Toggle(isOn: $bottle.settings.settings.dxvk) {
                        Text("config.dxvk")
                    }
                    .onChange(of: bottle.settings.settings.dxvk) { enabled in
                        if enabled {
                            print("Enabling DXVK")
                            bottle.enableDXVK()
                        } else {
                            print("Disabling DXVK")
                            bottle.disableDXVK()
                        }
                    }

                    Toggle(isOn: $bottle.settings.settings.dxvkHud) {
                        Text("config.dxvkHud")
                    }
                    .disabled(!bottle.settings.settings.dxvk)
                }
                Section("config.title.metal") {
                    Toggle(isOn: $bottle.settings.settings.metalHud) {
                        Text("config.metalHud")
                    }
                    Toggle(isOn: $bottle.settings.settings.metalTrace) {
                        Text("config.metalTrace")
                        Text("config.metalTrace.info")
                    }
                }
                Section {
                    Toggle(isOn: $bottle.settings.settings.esync) {
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
        }
        .navigationTitle("\(bottle.name) \(NSLocalizedString("tab.config", comment: ""))")
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(bottle: .constant(Bottle()))
    }
}
