//
//  hdiutil.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import Foundation

class Hdiutil {
    static let hdiutilBinary: URL = URL(filePath: "/usr/bin/hdiutil")

    static func mount(url: URL) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = hdiutilBinary
        process.arguments = ["attach", url.path.trimmingCharacters(in: .whitespacesAndNewlines)]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(decoding: output, as: UTF8.self)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw Failure.unknownError(outputString)
            }

            if let range = outputString.range(of: "/Volumes") {
                let volumePath = outputString[range.lowerBound...]
                return String(volumePath).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        throw Failure.failedToGetURL
    }

    static func unmount(path: String) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = hdiutilBinary
        process.arguments = ["unmount", path]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(decoding: output, as: UTF8.self)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw Failure.unknownError(outputString)
            }
        }
    }

    enum Failure: Error {
        case failedToGetURL
        case unknownError(String)
    }
}

extension Hdiutil.Failure: CustomStringConvertible {
    var description: String {
        switch self {
        case .failedToGetURL:
            "Failed to get URL"
        case .unknownError(let string):
            "Unknown Error: \(string)"
        }
    }
}
