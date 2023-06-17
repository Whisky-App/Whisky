//
//  Ditto.swift
//  Whisky
//
//  Created by Isaac Marovitz on 17/06/2023.
//

import Foundation

class Ditto {
    static let dittoBinary: URL = URL(fileURLWithPath: "/usr/bin/ditto")

    static func ditto(fromPath: String, toPath: String) {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = dittoBinary
        process.arguments = ["\(fromPath)", "\(toPath)"]
        process.standardOutput = pipe
        process.standardInput = pipe

        do {
            try process.run()
            _ = try pipe.fileHandleForReading.readToEnd()
        } catch {}

        process.waitUntilExit()
    }
}
