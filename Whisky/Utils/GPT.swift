//
//  GPT.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import Foundation

// GPT = Game Porting Toolkit
class GPT {
    static let applicationFolder: URL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)[0]
    static let libFolder: URL = applicationFolder
        .appendingPathComponent("Whisky.app")
        .appendingPathComponent("Contents")
        .appendingPathComponent("Resources")
        .appendingPathComponent("Libraries")
        .appendingPathComponent("Wine")
        .appendingPathComponent("lib")

    static let externalFolder: URL = libFolder
        .appendingPathComponent("external")

    static func isGPTInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: externalFolder.path)
    }

    static func install(url: URL) {
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
                print("Failed to create enumerator")
            }

            try Hdiutil.unmount(path: path)
        } catch {
            print(error)
        }
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
