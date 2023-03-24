//
//  Wine.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

class Wine {
    static let binFolder: URL = (Bundle.main.resourceURL ?? URL(fileURLWithPath: ""))
        .appendingPathComponent("Libraries")
        .appendingPathComponent("Wine")
        .appendingPathComponent("bin")

    static let wineBinary: URL = binFolder
        .appendingPathComponent("wine64")

    static func run(_ args: [String]) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = wineBinary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        process.currentDirectoryURL = binFolder

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(decoding: output, as: UTF8.self)
            print(outputString)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw outputString
            }

            return outputString
        }

        return ""
    }

    static func version() async throws -> String {
        return try await run(["--version"])
    }

    static func cfg() async throws -> String {
        return try await run(["winecfg"])
    }
}

extension String: Error {}
