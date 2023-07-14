//
//  UTTypeExtensions.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/07/2023.
//

import UniformTypeIdentifiers

extension UTType {
    static let msiInstaller = UTType(importedAs: "com.microsoft.msi-installer")
    static let shortcut = UTType(importedAs: "com.microsoft.lnk-shortcut")
}
