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

            if let pathEnumerator = FileManager.default.enumerator(atPath: path) {
                while let relativePath = pathEnumerator.nextObject() as? String {
                    let subItemAt = URL(fileURLWithPath: path).appendingPathComponent(relativePath).path
                    let subItemTo = libFolder.appendingPathComponent(relativePath).path

                    if isDir(atPath: subItemAt) {
                        if !isDir(atPath: subItemTo) {
                            try FileManager.default.createDirectory(atPath: subItemTo,
                                                                    withIntermediateDirectories: true)
                        }
                    } else {
                        if isFile(atPath: subItemTo) {
                            try FileManager.default.removeItem(atPath: subItemTo)
                        }

                        try FileManager.default.copyItem(atPath: subItemAt, toPath: subItemTo)
                    }
                }
                print("GPT Installed")
            } else {
                gptError(error: "Failed to create enumerator!")
            }

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
