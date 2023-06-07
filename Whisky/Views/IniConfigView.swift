//
//  INIConfigView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 07/06/2023.
//

import SwiftUI

struct INIConfigView: View {
    @Binding var config: INIConfig
    
    var body: some View {
        LazyVStack {
            ForEach(config.keys.sorted(), id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(config[key]!.keys.sorted(), id: \.self) { subKey in
                        HStack {
                            Text(subKey)
                            Spacer()
                            Text(config[key]![subKey]!.displayString())
                        }
                    }
                }
            }
        }
    }
}

extension INIValue {
    func displayString() -> String {
        switch self {
        case .string(let str):
            return str
        case .dword(let dword):
            return String(dword)
        case .qword(let qword):
            return String(qword)
        case .hex(let hex):
            return hex.map { $0.map { String(format: "%02x", $0) }.joined() }.joined(separator: " ")
        }
    }
}


struct INIConfigView_Previews: PreviewProvider {
    static var previews: some View {
        INIConfigView(config: .constant([
            "Section": [
                "Key": .string("Value"),
                "Key2": .dword(43),
                "Key3": .qword(43243243232),
                "Key4": .hex([
                    [1, 2, 3, 4],
                    [5, 6, 7, 8]
                ])
            ]
        ]))
    }
}
