//
//  IniConfigView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import SwiftUI

struct IniConfigView: View {
    @Binding var iniConfig: INIConfig

    var body: some View {
        List {
            ForEach(iniConfig.keys.sorted(), id: \.self) { section in
                iniConfigSectionView(section: section)
            }
        }
    }
    
    @ViewBuilder
    private func iniConfigSectionView(section: String) -> some View {
        if let sectionConfig = iniConfig[section] {
            Section(header: Text(section)) {
                ForEach(sectionConfig.keys.sorted(), id: \.self) { key in
                    iniConfigItemView(section: section, key: key)
                }
            }
        }
    }
    
    @ViewBuilder
    private func iniConfigItemView(section: String, key: String) -> some View {
        if let value = iniConfig[section]?[key] {
            HStack {
                Text(key)
                Spacer()
                TextField("Value", text: Binding(
                    get: { value },
                    set: { newValue in
                        iniConfig[section]?[key] = newValue
                    }
                )).foregroundColor(.secondary)
            }
        }
    }
}

struct IniConfigView_Previews: PreviewProvider {
    static var previews: some View {
        IniConfigView(iniConfig: .constant([
            "Section": [
                "Key": "Value"
            ],
            "Section 2": [
                "Key": "Value",
                "Key 2": "Value 2",
            ]
        ]))
    }
}
