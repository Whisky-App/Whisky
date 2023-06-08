//
//  INIConfigView.swift
//  Whisky
//
//  Created by Amrit Bhogal on 07/06/2023.
//

import SwiftUI

class StringReference {
    public var value: String
    
    public init(_ value: String) {
        self.value = value
    }
}

extension String: Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(StringReference(self))
    }
}

struct INIConfigView: View {
    @Binding var config: INIConfig
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(buildHierarchy(from: config), id: \.id) { item in
                    outlineGroup(for: item)
                }
            }
        }
    }
    
    private func outlineGroup(for item: SectionItem) -> some View {
        OutlineGroup(item.subItems!, id: \.id, children: \.subItems) { subItem in
            Text(subItem.title)
        }
    }
    
    private func buildHierarchy(from config: INIConfig) -> [SectionItem] {
        var rootItems: [SectionItem] = []
        
        for (key, subConfig) in config {
            var currentNode = SectionItem(title: key)
            var currentParent = currentNode
            let components = key.split(separator: "\\")
            
            for component in components.dropFirst() {
                let newNode = SectionItem(title: String(component))
                currentParent.subItems!.append(newNode)
                currentParent = currentParent.subItems!.last!
            }
            
            for (subKey, value) in subConfig {
                let newItem = SectionItem(title: "\(subKey) = \"\(value)\"")
                currentParent.subItems!.append(newItem)
            }
            
            rootItems.append(currentNode)
        }
        
        return rootItems
    }
}

struct SectionItem: Identifiable {
    var id = UUID()
    var title: String
    var subItems: [SectionItem]? = []
}


extension INIValue {
    func displayView() -> some View {
        switch self {
        case .string(let string):
            return AnyView(
                Text(string)
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(5)
            )
            
        case .dword(let dword):
            return AnyView(
                Text(String(dword))
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(5)
            )
            
        case .qword(let qword):
            return AnyView(
                Text(String(qword))
                    .font(.subheadline)
                    .padding(5)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(5)
            )
            
        case .hex(let array):
            return AnyView(
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(array, id: \.self) { row in
                        HStack {
                            ForEach(row, id: \.self) { item in
                                Text(String(format: "%02X", item))
                            }
                        }
                    }
                }
                .font(.subheadline)
                .padding(5)
                .background(Color.purple.opacity(0.2))
                .cornerRadius(5)
            )
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
