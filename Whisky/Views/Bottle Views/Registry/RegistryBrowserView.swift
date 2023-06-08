//
//  RegistryBrowserView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI

struct RegistryBrowserView: View {
    @ObservedObject var viewModel: RegistrySectionVM
    
    var body: some View {
        List {
            ForEach(viewModel.children, id: \.name) { child in
                NavigationLink(destination: RegistryBrowserView(viewModel: child)) {
                    Text(child.name)
                }
            }
            ForEach(Array(viewModel.values.keys), id: \.self) { key in
                NavigationLink(destination: RegistrySectionEditorView(viewModel: viewModel, key: key)) {
                    Text(key)
                }
            }
        }
        .navigationTitle(viewModel.name)
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
