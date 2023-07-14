//
//  UTTypeExtensions.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/07/2023.
//

import UniformTypeIdentifiers

extension UTType {
    static let portableExecutable = UTType(exportedAs: "com.microsoft.portable-executable")
    static let msiInstaller = UTType(exportedAs: "com.microsoft.msi-installer")
    static let shortcut = UTType(exportedAs: "com.microsoft.shortcut")
}
