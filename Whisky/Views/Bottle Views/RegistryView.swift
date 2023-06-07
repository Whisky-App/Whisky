//
//  RegistryView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import SwiftUI

struct RegistryView: View {
    @Binding var registry: Registry

    var body: some View {
        TabView {
            IniConfigView(iniConfig: $registry.entries.system)
                .tabItem {
                    Label("System", systemImage: "gearshape")
                }

            IniConfigView(iniConfig: $registry.entries.user)
                .tabItem {
                    Label("User", systemImage: "person")
                }

            IniConfigView(iniConfig: $registry.entries.userDefines)
                .tabItem {
                    Label("User Defines", systemImage: "pencil")
                }
        }
    }
}

struct RegistryView_Previews: PreviewProvider {
    static var previews: some View {
        RegistryView(registry: .constant(Registry(mockData: Registry.Entries(
            system: [
                "Section": [
                    "Key": "Value",
                ],
                "Section 2": [
                    "Key": "Value",
                    "Key 2": "Value 2",
                ]
            ], user: [
                "Section": [
                    "Key": "Value",
                ],
                
                "Section 2": [
                    "Key": "Value",
                    "Key 2": "Value 2",
                ]
            ], userDefines: [
                "Section": [
                    "Key": "Value"
                ],
                "Section 2": [
                    "Key": "Value",
                    "Key 2": "Value 2",
                ]
            ]
        ))))
    }
}
