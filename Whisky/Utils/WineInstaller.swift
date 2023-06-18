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

            // Write the build version into the Wine directory
            let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
            let buildVersionFile = whiskySupportFolder.appendingPathComponent("Libraries")
                .appendingPathComponent("build_version")
            try buildVersion.write(to: buildVersionFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to install Wine: \(error)")
        }
    }

    static func updateWine() {
        // Read the build version from the Wine directory
        let buildVersionFile = WineInstaller.libraryFolder.appendingPathComponent("build_version")
        let buildVersion = try? String(contentsOf: buildVersionFile, encoding: .utf8)

        if buildVersion != Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            WineInstaller.installWine()
        }
    }
}
