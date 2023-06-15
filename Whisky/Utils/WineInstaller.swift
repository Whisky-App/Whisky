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
        .appendingPathExtension("zip")

    static let libraryFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")
        .appendingPathComponent("Libraries")

    static func isWineInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: libraryFolder.path())
    }

    static func installWine() {
        do {
            let whiskySupportFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask)[0]
                .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")

            if !FileManager.default.fileExists(atPath: whiskySupportFolder.path()) {
                try FileManager.default.createDirectory(at: whiskySupportFolder, withIntermediateDirectories: true)
            }

            try Unzip.unzip(zipFile: libraryArchive, toURL: whiskySupportFolder)
        } catch {
            // Do not use localized strings here: it makes debugging harder
            print("Failed to install Wine: \(error)")
        }
    }
}
