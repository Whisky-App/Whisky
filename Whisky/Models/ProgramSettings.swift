//
//  ProgramSettings.swift
//  Whisky
//
//  Created by Isaac Marovitz on 06/04/2023.
//

import Foundation

struct ProgramSettingsData: Codable {
    var environment: [String: String] = [:]
    var arguments: String = ""
    var workDir: String = ""
}

class ProgramSettings {
    var settings: ProgramSettingsData {
        didSet {
            encode()
        }
    }

    var environment: [String: String] {
        get {
            return settings.environment
        }
        set {
            settings.environment = newValue
        }
    }

    var arguments: String {
        get {
            return settings.arguments
        }
        set {
            settings.arguments = newValue
        }
    }

    var workDir: String {
        get {
            return settings.workDir
        }
        set {
            settings.workDir = newValue
        }
    }

    let settingsUrl: URL

    init(bottleUrl: URL, name: String) {
        let settingsFolder = bottleUrl.appendingPathComponent("Program Settings")
        self.settingsUrl = settingsFolder
                                    .appendingPathComponent(name)
                                    .appendingPathExtension("plist")

        if !FileManager.default.fileExists(atPath: settingsFolder.path) {
            do {
                try FileManager.default.createDirectory(at: settingsFolder, withIntermediateDirectories: true)
            } catch {
                print(error)
            }
        }

        settings = ProgramSettingsData()
        if !decode() {
            encode()
        }
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(ProgramSettingsData.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
