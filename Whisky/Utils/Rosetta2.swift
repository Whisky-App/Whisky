//
//  Rosetta2.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation

class Rosetta2 {
    static let rosetta2RuntimeBin = "/Library/Apple/usr/libexec/oah/libRosettaRuntime"

    static let isRosettaInstalled: Bool = {
        return FileManager.default.fileExists(atPath: rosetta2RuntimeBin)
    }()

    static func installRosetta() async -> Bool {
        let process = Process()
        let pipe = Pipe()
        guard let log = Log(bottle: nil,
                            args: [],
                            environment: nil) else {
            return false
        }

        process.launchPath = "/usr/sbin/softwareupdate"
        process.arguments = ["--install-rosetta", "--agree-to-license"]
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { pipe in
            let line = String(decoding: pipe.availableData, as: UTF8.self)
            log.write(line: "\(line)", printLine: false)
        }

        do {
            try process.run()
            var isRunning = true
            log.write(line: "Launched Rosetta Install (\(process.processIdentifier))\n")

            while isRunning {
                process.waitUntilExit()
                if pipe.fileHandleForReading.availableData.count == 0 {
                    isRunning = false
                }
            }
            log.write(line: "Process exited with code \(process.terminationStatus)")
            _ = try pipe.fileHandleForReading.readToEnd()

            if process.terminationStatus != 0 {
                log.write(line: "Failed to install Rosetta 2: \(process.terminationStatus)")
                return false
            }

            return true
        } catch {
            return false
        }
    }
}
