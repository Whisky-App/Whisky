//
//  RegistrySectionVM.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI
import Combine

class RegistrySectionVM: ObservableObject {
    @Published var name: String
    @Published var children: [RegistrySectionVM]
    @Published var values: [String: RegistryValue]
    
    init(name: String, children: [RegistrySectionVM] = [], values: [String: RegistryValue] = [:]) {
        self.name = name
        self.children = children
        self.values = values
    }
    
    static func fromRegistryConfig(_ config: RegistryConfig) -> [RegistrySectionVM] {
        var sectionTree: [String: RegistrySectionVM] = [:]
        
        for (key, values) in config {
            let sections = key.split(separator: "\\")
            var parent: RegistrySectionVM? = nil
            
            for section in sections {
                let sectionName = String(section)
                if sectionTree[sectionName] == nil {
                    let newSection = RegistrySectionVM(name: sectionName)
                    sectionTree[sectionName] = newSection
                    
                    parent?.children.append(newSection)
                }
                parent = sectionTree[sectionName]
            }
            parent?.values = values
        }
        return Array(sectionTree.values)
    }
}

