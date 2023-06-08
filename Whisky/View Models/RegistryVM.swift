//
//  RegistryVM.swift
//  Whisky
//
//  Created by Amrit Bhogal on 08/06/2023.
//

import SwiftUI
import Combine

class RegistryViewModel: ObservableObject {
    @Published var name: String
    @Published var children: [RegistryViewModel]
    @Published var values: [String: INIValue]
    
    init(name: String, children: [RegistryViewModel] = [], values: [String: INIValue] = [:]) {
        self.name = name
        self.children = children
        self.values = values
    }
    
    static func fromINIConfig(_ config: INIConfig) -> [RegistryViewModel] {
        var sectionTree: [String: RegistryViewModel] = [:]
        
        for (key, values) in config {
            let sections = key.split(separator: "\\")
            var parent: INISectionViewModel? = nil
            
            for section in sections {
                let sectionName = String(section)
                if sectionTree[sectionName] == nil {
                    let newSection = INISectionViewModel(name: sectionName)
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
