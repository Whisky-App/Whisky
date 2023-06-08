//
//  RegistrySectionEditorView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI

struct RegistrySectionEditorView: View {
    @ObservedObject var viewModel: RegistrySectionVM
    var key: String
    
    @State private var stringValue: String = ""
    @State private var dwordValue: String = ""
    @State private var qwordValue: String = ""
    @State private var hexValue: String = ""
    
    var body: some View {
        VStack {
            if var vals = viewModel.values {
                switch vals[key] {
                case .string(let value):
                    TextField("String Value", text: $stringValue, onCommit: {
                        vals[key] = .string(stringValue)
                    })
                    .onAppear {
                        stringValue = value
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    
                case .dword(let value):
                    TextField("DWord Value", text: $dwordValue, onCommit: {
                        if let uintValue = UInt32(dwordValue) {
                            vals[key] = .dword(uintValue)
                        }
                    })
                    .onAppear {
                        dwordValue = String(value)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    
                case .qword(let value):
                    TextField("QWord Value", text: $qwordValue, onCommit: {
                        if let uintValue = UInt64(qwordValue) {
                            vals[key] = .qword(uintValue)
                        }
                    })
                    .onAppear {
                        qwordValue = String(value)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    
                case .hex(let array):
                    TextField("Hex Value", text: $hexValue, onCommit: {
                        // Parse hex string and convert to array of UInt8
                        let bytes = hexValue.split(separator: " ").compactMap { UInt8($0, radix: 16) }
                        vals[key] = .hex([bytes])
                    })
                    .onAppear {
                        hexValue = array.map { row in
                            row.map { String(format: "%02X", $0) }.joined(separator: " ")
                        }.joined(separator: "\n")
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    
                default:
                    Text("Unsupported type")
                }
            } else {
                Text("No values")
            }
            
            Spacer()
            
            RegistryValueView(value: viewModel.values![key] ?? .string("")).padding()
            
        }
        .navigationTitle(key)
    }
}
struct RegistrySectionEditorView_Previews: PreviewProvider {
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
        
        return RegistrySectionEditorView(viewModel: rootViewModel, key: "Root")
    }
}
