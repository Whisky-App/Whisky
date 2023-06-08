//
//  RegistrySectionVM.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI
import Combine

class RegistrySectionVM: ObservableObject {
    let name: String
    weak var parent: RegistrySectionVM?
    var values: [String: RegistryValue]?
    var children: [RegistrySectionVM]?
    
    @Published var selectedChild: RegistrySectionVM?
    
    init(name: String, parent: RegistrySectionVM? = nil, values: [String: RegistryValue]? = nil, children: [RegistrySectionVM]? = nil) {
        self.name = name
        self.parent = parent
        self.values = values
        self.children = children ?? []
    }
    
    static func fromRegistryConfig(_ config: RegistryConfig) -> [RegistrySectionVM] {
        var sectionMap: [String: RegistrySectionVM] = [:]
        
        for (keyPath, values) in config {
            var parent: RegistrySectionVM?
            let sections = keyPath.components(separatedBy: "\\\\")
            var path = ""
            
            for section in sections {
                path = path.isEmpty ? section : "\(path)\\\(section)"
                if let existingSection = sectionMap[path] {
                    parent = existingSection
                } else {
                    let newSection = RegistrySectionVM(name: section, parent: parent)
                    parent?.children!.append(newSection)
                    parent = newSection
                    sectionMap[path] = newSection
                }
            }
            
            parent?.values = values
        }
        
        // Return top-level sections
        return sectionMap.values.filter { $0.parent == nil }
    }
}

