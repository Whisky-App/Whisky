//
//  Installer.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/06/2023.
//

import Foundation

class WineInstaller {
    static let libraryArchive: URL = (Bundle.main.resourceURL ?? URL(fileURLWithPath: ""))
        .appendingPathComponent("Libraries")
        .appendingPathExtension("tar")
        .appendingPathExtension("gz")

    static let libraryFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Whisky")
        .appendingPathComponent("Libraries")

    static func isWineInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: libraryFolder.path)
    }

    static func installWine() {
        do {
            let whiskySupportFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask)[0]
                .appendingPathComponent("Whisky")

            if !FileManager.default.fileExists(atPath: whiskySupportFolder.path) {
                try FileManager.default.createDirectory(at: whiskySupportFolder, withIntermediateDirectories: true)
            }

            try Tar.untar(tarBall: libraryArchive, toURL: whiskySupportFolder)
        } catch {
            print("Failed to install Wine: \(error)")
        }
    }
}
