//
//  GPT.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import Foundation
import AppKit

// GPT = Game Porting Toolkit
class GPT {
    static func isGPTInstalled() -> Bool {
        let libFolder: URL = WineInstaller.libraryFolder
            .appendingPathComponent("Wine")
            .appendingPathComponent("lib")

        let d3dmFolder: URL = libFolder
            .appendingPathComponent("external")
            .appendingPathComponent("D3DMetal.framework")

        return FileManager.default.fileExists(atPath: d3dmFolder.path)
    }

    static func install(url: URL) {
        let libFolder: URL = WineInstaller.libraryFolder
            .appendingPathComponent("Wine")
            .appendingPathComponent("lib")

        do {
            let path = try Hdiutil.mount(url: url) + "/lib"

            Ditto.ditto(fromPath: path, toPath: libFolder.path)

            let d3dmSym = libFolder
                .appendingPathComponent("D3DMetal")
                .appendingPathExtension("framework")
            let libSym = libFolder
                .appendingPathComponent("libd3dshared")
                .appendingPathExtension("dylib")
            let d3dmOg = libFolder
                .appendingPathComponent("external")
                .appendingPathComponent("D3DMetal")
                .appendingPathExtension("framework")
            let libOg = libFolder
                .appendingPathComponent("external")
                .appendingPathComponent("libd3dshared")
                .appendingPathExtension("dylib")

            try FileManager.default.createSymbolicLink(at: d3dmSym, withDestinationURL: d3dmOg)
            try FileManager.default.createSymbolicLink(at: libSym, withDestinationURL: libOg)

            try Hdiutil.unmount(path: path)
        } catch {
            print(error)
        }
    }

    static func gptError(error: String) {
        let alert = NSAlert()
        alert.messageText = String(localized: "gptalert.message")
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
