//
//  Wine.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

class Wine {
    static let binFolder: URL = Bundle.main.resourceURL ?? URL(fileURLWithPath: "")
        .appendingPathComponent("Libraries")
        .appendingPathComponent("Wine")
        .appendingPathComponent("bin")

    static let wineBinary: URL = binFolder
        .appendingPathComponent("wine64")

    static let winecfg: URL = binFolder
        .appendingPathComponent("winecfg")

    static func version() throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = wineBinary
        process.arguments = ["--version"]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw String(decoding: output, as: UTF8.self)
            }

            return String(decoding: output, as: UTF8.self)
        }

        return ""
    }

    static func cfg() throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = wineBinary
        process.arguments = ["start", "/unix", "\"\(winecfg.path)\""]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            print(String(decoding: output, as: UTF8.self))
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw String(decoding: output, as: UTF8.self)
            }

            return String(decoding: output, as: UTF8.self)
        }

        return ""
    }
}

extension String: Error {}
