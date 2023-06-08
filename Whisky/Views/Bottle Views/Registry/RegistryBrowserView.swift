//
//  RegistryBrowserView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI

import SwiftUI

struct RegistryBrowserView: View {
    @ObservedObject var viewModel: RegistrySectionVM
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                OutlineGroup(viewModel.children!, id: \.name, children: \.children) { childViewModel in
                    Text(childViewModel.name)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedChild = childViewModel
                        }
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)
        }
        
        // Content View
        if let selectedSection = viewModel.selectedChild {
            RegistrySectionContentView(viewModel: selectedSection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Select a Registry Section")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


struct RegistryBrowserView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleConfig: RegistryConfig = [
            "HKEY_LOCAL_MACHINE\\Software": [
                "stringKey": .string("stringValue"),
                "dwordKey": .dword(1234),
                "qwordKey": .qword(5678),
                "hexKey": .hex([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]])
            ],
            "HKEY_CURRENT_USER\\Software": [
                "stringKey": .string("anotherStringValue"),
                "dwordKey": .dword(4321),
                "qwordKey": .qword(8765),
                "hexKey": .hex([[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]])
            ]
        ]
        
        let rootViewModel = RegistrySectionVM(name: "Root",
                                              children: RegistrySectionVM.fromRegistryConfig(sampleConfig))
        
        return RegistryBrowserView(viewModel: rootViewModel)
    }
}
