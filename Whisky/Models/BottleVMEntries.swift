//
//  BottleVMEntries.swift
//  Whisky
//
//  Created by Josh on 6/22/23.
//

import Foundation

struct BottleEntries: Codable {
    var fileVersion: Semver = Semver(major: 1, minor: 0, patch: 0)
    var paths: [URL] = []
}

class BottleVMEntries {
    static let containerDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")
    
    static let bottleEntriesDir = containerDir
        .appendingPathComponent("BottleVM")
        .appendingPathExtension("json")
    
    private var file: BottleEntries {
        didSet {
            encode()
        }
    }
    
    var paths: [URL] {
        get {
            file.paths
        }
        set {
            file.paths = newValue
        }
    }
    
    static func exists() -> Bool {
        return FileManager.default.fileExists(atPath: Self.bottleEntriesDir.path())
    }
    
    init() {
        file = .init()
        
        if !Self.exists() {
            return;
        }
        
        if !decode() {
            encode()
        }
    }
    
    @discardableResult
    func decode() -> Bool {
        let decoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: Self.bottleEntriesDir)
            file = try decoder.decode(BottleEntries.self, from: data)
            
            if file.fileVersion != BottleEntries().fileVersion {
                print("Invalid file version \(file.fileVersion)")
                return false
            }
            
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    public func encode() -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(file)
            try data.write(to: Self.bottleEntriesDir)
            return true
        } catch {
            return false
        }
    }
}
