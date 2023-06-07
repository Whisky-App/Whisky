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
        print(url.path)
    }
}
