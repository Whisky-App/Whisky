//
//  IniConfigView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import SwiftUI

struct IniConfigView: View {
    var iniConfig: IniConfig

    var body: some View {
        List {
            ForEach(iniConfig.sorted(by: { $0.key < $1.key }), id: \.key) { section, sectionConfig in
                Section(header: Text(section)) {
                    ForEach(sectionConfig.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                            Spacer()
                            Text(value).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}
struct IniConfigView_Previews: PreviewProvider {
    static var previews: some View {
        IniConfigView(iniConfig: [
            "Test group": [
                "key": "value"
            ]])
    }
}
