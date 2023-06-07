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
            INIConfigView(config: $registry.entries.system)
                .tabItem {
                    Label("System", systemImage: "gearshape")
                }

            INIConfigView(config: $registry.entries.user)
                .tabItem {
                    Label("User", systemImage: "person")
                }

            INIConfigView(config: $registry.entries.userDefines)
                .tabItem {
                    Label("User Defines", systemImage: "pencil")
                }
        }
    }
}

struct RegistryView_Previews: PreviewProvider {
    static var previews: some View {
        RegistryView(registry: .constant(Registry(mockData: Registry.Entries())))
    }
}
