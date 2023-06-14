//
//  Unzip.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/06/2023.
//

import Foundation

class Unzip {
    static let unzipBinary: URL = URL(fileURLWithPath: "/usr/bin/unzip")

    static func unzip(zipFile: URL, toURL: URL) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = unzipBinary
        process.arguments = ["-q", "\(zipFile.path)", "-d", "\(toURL.path)"]
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(decoding: output, as: UTF8.self)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw outputString
            }
        }
    }
}
