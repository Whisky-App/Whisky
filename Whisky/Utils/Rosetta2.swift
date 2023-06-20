//
//  Rosetta2.swift
//  Whisky
//
//  Created by Venti on 20/06/2023.
//

import Foundation

class Rosetta2 {
    static let rosetta2RuntimeBin = "/Library/Apple/usr/libexec/oah/libRosettaRuntime"

    static let isRosettaInstalled: Bool = {
        return FileManager.default.fileExists(atPath: rosetta2RuntimeBin)
    }()

    static func launchRosettaInstaller() {
        let task = Process()
        task.launchPath = "/usr/sbin/softwareupdate"
        task.arguments = ["--install-rosetta"]
        do {
            try task.run()
        } catch {
            NSLog("Failed to install Rosetta 2: \(error)")
        }
    }
}
