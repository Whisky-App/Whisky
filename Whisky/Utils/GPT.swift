//
//  GPT.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import Foundation

// GPT = Game Porting Toolkit
class GPT {
    static let externalFolder: URL =  (Bundle.main.resourceURL ?? URL(fileURLWithPath: ""))
        .appendingPathComponent("Libraries")
        .appendingPathComponent("Wine")
        .appendingPathComponent("lib")
        .appendingPathComponent("external")

    static func isGPTInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: externalFolder.path)
    }

    static func install(url: URL) {
        do {
            let url = try Hdiutil.mount(url: url)
            let pathEnumerator = FileManager.default.enumerator(atPath: url.path)

            while let relativePath = pathEnumerator?.nextObject() as? String {
                let subItemAtPath = url.appendingPathComponent(relativePath).path
                let subItemToPath = externalFolder.appendingPathComponent(relativePath).path

                if isDir(atPath: subItemAtPath) {
                    if !isDir(atPath: subItemToPath) {
                        try FileManager.default.createDirectory(atPath: subItemToPath,
                                                                withIntermediateDirectories: true)
                    }
                } else {
                    if isFile(atPath: subItemToPath) {
                        try FileManager.default.removeItem(atPath: subItemToPath)
                    }

                    try FileManager.default.copyItem(atPath: subItemAtPath, toPath: subItemToPath)
                }
            }

            print("GPT Installed")
            try Hdiutil.unmount(url: url)
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
