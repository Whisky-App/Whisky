//
//  GPTK.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import Foundation
import AppKit

// GPTK = Game Porting Toolkit
class GPTK {
    static let libFolder: URL = WineInstaller.libraryFolder
        .appendingPathComponent("Wine")
        .appendingPathComponent("lib")

    static let d3dmSym = libFolder
        .appendingPathComponent("D3DMetal")
        .appendingPathExtension("framework")

    static let d3dmOg = libFolder
        .appendingPathComponent("external")
        .appendingPathComponent("D3DMetal")
        .appendingPathExtension("framework")

    static let libSym = libFolder
        .appendingPathComponent("libd3dshared")
        .appendingPathExtension("dylib")

    static let libOg = libFolder
        .appendingPathComponent("external")
        .appendingPathComponent("libd3dshared")
        .appendingPathExtension("dylib")

    static func isGPTKInstalled() -> Bool {
        let libFolder: URL = WineInstaller.libraryFolder
            .appendingPathComponent("Wine")
            .appendingPathComponent("lib")

        let d3dmFolder: URL = libFolder
            .appendingPathComponent("external")
            .appendingPathComponent("D3DMetal.framework")

        return FileManager.default.fileExists(atPath: d3dmFolder.path)
    }

    static func install(url: URL) {
        do {
            let path = try Hdiutil.mount(url: url) + "/redist/lib"

            Ditto.ditto(fromPath: path, toPath: libFolder.path)

            try FileManager.default.createSymbolicLink(at: d3dmSym, withDestinationURL: d3dmOg)
            try FileManager.default.createSymbolicLink(at: libSym, withDestinationURL: libOg)

            try Hdiutil.unmount(path: path)
        } catch {
            print(error)
        }
    }

    static func uninstall() {
        do {
            try FileManager.default.removeItem(at: d3dmSym)
            try FileManager.default.removeItem(at: d3dmOg)
            try FileManager.default.removeItem(at: libSym)
            try FileManager.default.removeItem(at: libOg)
        } catch {
            print(error)
        }
    }

    struct VersionInfo: Codable {
        let CFBundleShortVersionString: String
    }

    static func gptkVersion() -> String? {
        do {
            let versionPlist = d3dmOg
                .appendingPathComponent("Versions")
                .appendingPathComponent("A")
                .appendingPathComponent("Resources")
                .appendingPathComponent("version")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(VersionInfo.self, from: data)
            return info.CFBundleShortVersionString
        } catch {
            return nil
        }
    }

    static func gptkError(error: String) {
        let alert = NSAlert()
        alert.messageText = String(localized: "gptkalert.message")
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: String(localized: "button.ok"))
        alert.runModal()
    }

    private static func isDir(atPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDir)
        return exist && isDir.boolValue
    }

    private static func isFile(atPath: String) -> Bool {
        var isDir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: atPath, isDirectory: &isDir)
        return exist && !isDir.boolValue
    }
}
