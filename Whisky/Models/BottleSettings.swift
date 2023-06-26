//
//  BottleSettings.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation
import SemanticVersion

struct Shortcut: Codable {
    var name: String
    var link: URL
}

struct BottleInfo: Codable {
    var name: String = "Whisky"
    var shortcuts: [Shortcut] = []
}

struct BottleWineConfig: Codable {
    var wineVersion: SemanticVersion = SemanticVersion(7, 7, 0)
    var windowsVersion: WinVersion = .win10
}

struct BottleGameToolkitConfig: Codable {
    var metalHud: Bool = false
    var metalTrace: Bool = false
    var esync: Bool = false
}

struct BottleMetadata: Codable {
    var fileVersion: SemanticVersion = SemanticVersion(1, 0, 0)
    var info: BottleInfo = .init()
    var wineConfig: BottleWineConfig = .init()
    var gameToolkitConfig: BottleGameToolkitConfig = .init()
}

class BottleSettings {
    private let bottleUrl: URL
    private let metadataUrl: URL
    var settings: BottleMetadata {
        didSet {
            encode()
        }
    }
    var wineVersion: SemanticVersion {
        get {
            return settings.wineConfig.wineVersion
        }
        set {
            settings.wineConfig.wineVersion = newValue
        }
    }
    var windowsVersion: WinVersion {
        get {
            return settings.wineConfig.windowsVersion
        }
        set {
            settings.wineConfig.windowsVersion = newValue
        }
    }
    var metalHud: Bool {
        get {
            return settings.gameToolkitConfig.metalHud
        }
        set {
            settings.gameToolkitConfig.metalHud = newValue
        }
    }
    var metalTrace: Bool {
        get {
            return settings.gameToolkitConfig.metalTrace
        }
        set {
            settings.gameToolkitConfig.metalTrace = newValue
        }
    }
    var esync: Bool {
        get {
            return settings.gameToolkitConfig.esync
        }
        set {
            settings.gameToolkitConfig.esync = newValue
        }
    }
    var name: String {
        get {
            return settings.info.name
        } set {
            settings.info.name = newValue
        }
    }
    var shortcuts: [Shortcut] {
        get {
            return settings.info.shortcuts
        }
        set {
            settings.info.shortcuts = newValue
        }
    }
    init(bottleURL: URL) {
        bottleUrl = bottleURL
        metadataUrl = bottleURL
            .appendingPathComponent("Metadata")
            .appendingPathExtension("plist")
        settings = .init()
        if !decode() {
            encode()
        }
    }
    @discardableResult
    public func decode() -> Bool {
        let decoder = PropertyListDecoder()

        do {
            let data = try Data(contentsOf: self.metadataUrl)
            settings = try decoder.decode(BottleMetadata.self, from: data)
            if settings.fileVersion != BottleMetadata().fileVersion {
                print("Invalid file version \(settings.fileVersion)")
                return false
            }
            if settings.wineConfig.wineVersion != BottleWineConfig().wineVersion {
                print("Bottle has a different wine version!")
                settings.wineConfig.wineVersion = BottleWineConfig().wineVersion
            }
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(settings)
            try data.write(to: metadataUrl)
            return true
        } catch {
            return false
        }
    }

    func environmentVariables(environment: inout [String: String]) {
        if esync {
            environment.updateValue("1", forKey: "WINEESYNC")
        }

        if metalHud {
            environment.updateValue("1", forKey: "MTL_HUD_ENABLED")
        }

        if metalTrace {
            environment.updateValue("1", forKey: "METAL_CAPTURE_ENABLED")
        }
    }
}
