//
//  RegistryView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import SwiftUI

struct RegistryView: View {
    @Binding var registry: Registry
    
    var systemViewModel: RegistrySectionVM {
        RegistrySectionVM(name: "System", children: RegistrySectionVM.fromRegistryConfig(registry.entries.system))
    }
    
    var userViewModel: RegistrySectionVM {
        RegistrySectionVM(name: "User", children: RegistrySectionVM.fromRegistryConfig(registry.entries.user))
    }
    
    var userDefinesViewModel: RegistrySectionVM {
        RegistrySectionVM(name: "User Defines", children: RegistrySectionVM.fromRegistryConfig(registry.entries.userDefines))
    }
    
    var body: some View {
        TabView {
            NavigationView {
                RegistryBrowserView(viewModel: systemViewModel)
            }
            .tabItem {
                Label("System", systemImage: "gearshape")
            }

            NavigationView {
                RegistryBrowserView(viewModel: userViewModel)
            }
            .tabItem {
                Label("User", systemImage: "person")
            }

            NavigationView {
                RegistryBrowserView(viewModel: userDefinesViewModel)
            }
            .tabItem {
                Label("User Defines", systemImage: "pencil")
            }
        }
    }
}

struct RegistryView_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = Registry.Entries(
            system: [
                "HKEY_LOCAL_MACHINE\\Software": [
                    "stringValue": .string("Some system value"),
                    "dwordValue": .dword(12345),
                    "qwordValue": .qword(123456789),
                    "hexValue": .hex([[0x12, 0x34, 0x56, 0x78]])
                ]
            ],
            user: [
                "HKEY_CURRENT_USER\\Preferences": [
                    "theme": .string("Dark"),
                    "fontSize": .dword(12),
                    "sessionTimeout": .qword(3600)
                ]
            ],
            userDefines: [
                "HKEY_CURRENT_USER\\CustomDefines": [
                    "customKey": .string("Custom Value"),
                    "customDword": .dword(67890),
                    "customQword": .qword(987654321)
                ]
            ]
        )
        return RegistryView(registry: .constant(Registry(mockData: mockData)))
    }
}

