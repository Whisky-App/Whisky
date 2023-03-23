//
//  Wine.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

class Wine {
    static func version() throws -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = Bundle.main.resourceURL!
            .appendingPathComponent("Libraries")
            .appendingPathComponent("Wine")
            .appendingPathComponent("bin")
            .appendingPathComponent("wine64")
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        let output = try pipe.fileHandleForReading.readToEnd()!
        process.waitUntilExit()
        let status = process.terminationStatus
        if status != 0 {
            throw String(decoding: output, as: UTF8.self)
        }
        
        return String(decoding: output, as: UTF8.self)
    }
}

extension String: Error {}
