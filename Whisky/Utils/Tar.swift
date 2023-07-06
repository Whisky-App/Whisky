//
//  Tar.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/06/2023.
//

import Foundation

class Tar {
    static let tarBinary: URL = URL(fileURLWithPath: "/usr/bin/tar")

    static func tar(folder: URL, toURL: URL) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = tarBinary
        process.arguments = ["-zcf", "\(toURL.path)", "\(folder.path)"]
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

    static func untar(tarBall: URL, toURL: URL) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = tarBinary
        process.arguments = ["-xzf", "\(tarBall.path)", "-C", "\(toURL.path)"]
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
