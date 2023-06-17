//
//  Ditto.swift
//  Whisky
//
//  Created by Isaac Marovitz on 17/06/2023.
//

import Foundation

class Ditto {
    static let dittoBinary: URL = URL(fileURLWithPath: "/usr/bin/ditto")

    static func ditto(fromPath: String, toPath: String) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = dittoBinary
        process.arguments = ["\(fromPath)", "\(toPath)"]
        process.standardOutput = pipe
        process.standardInput = pipe

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
