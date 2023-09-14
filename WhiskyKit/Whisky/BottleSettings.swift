//
//  BottleSettings.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation
import SemanticVersion

public enum DXVKHUD: Codable {
    case full, partial, fps, off
}

public enum WinVersion: String, CaseIterable, Codable {
    case winXP = "winxp64"
    case win7 = "win7"
    case win8 = "win8"
    case win81 = "win81"
    case win10 = "win10"

    public func pretty() -> String {
        switch self {
        case .winXP:
            return "Windows XP"
        case .win7:
            return "Windows 7"
        case .win8:
            return "Windows 8"
        case .win81:
            return "Windows 8.1"
        case .win10:
            return "Windows 10"
        }
    }
}

public struct Shortcut: Codable {
    public var name: String
    public var link: URL

    public init(name: String, link: URL) {
        self.name = name
        self.link = link
    }
}

public struct BottleInfo: Codable {
    var name: String = "Whisky"
    var shortcuts: [Shortcut] = []
}

public struct BottleWineConfig: Codable {
    var wineVersion: SemanticVersion = SemanticVersion(7, 7, 0)
    var windowsVersion: WinVersion = .win10
    var esync: Bool = false
}

public struct BottleMetalConfig: Codable {
    var metalHud: Bool = false
    var metalTrace: Bool = false
}

public struct BottleDXVKConfig: Codable {
    var dxvk: Bool = false
    var dxvkHud: DXVKHUD = .off
}

public struct BottleMetadata: Codable {
    var fileVersion: SemanticVersion = SemanticVersion(1, 0, 0)
    var info: BottleInfo = .init()
    var wineConfig: BottleWineConfig = .init()
    var metalConfig: BottleMetalConfig = .init()
    var dxvkConfig: BottleDXVKConfig = .init()
}

public class BottleSettings {
    private let bottleUrl: URL
    private let metadataUrl: URL

    public var settings: BottleMetadata {
        didSet {
            encode()
        }
    }

    public var wineVersion: SemanticVersion {
        get {
            return settings.wineConfig.wineVersion
        }
        set {
            settings.wineConfig.wineVersion = newValue
        }
    }

    public var windowsVersion: WinVersion {
        get {
            return settings.wineConfig.windowsVersion
        }
        set {
            settings.wineConfig.windowsVersion = newValue
        }
    }

    public var esync: Bool {
        get {
            return settings.wineConfig.esync
        }
        set {
            settings.wineConfig.esync = newValue
        }
    }

    public var metalHud: Bool {
        get {
            return settings.metalConfig.metalHud
        }
        set {
            settings.metalConfig.metalHud = newValue
        }
    }

    public var metalTrace: Bool {
        get {
            return settings.metalConfig.metalTrace
        }
        set {
            settings.metalConfig.metalTrace = newValue
        }
    }

    public var dxvk: Bool {
        get {
            return settings.dxvkConfig.dxvk
        }
        set {
            settings.dxvkConfig.dxvk = newValue
        }
    }

    public var dxvkHud: DXVKHUD {
        get {
            return settings.dxvkConfig.dxvkHud
        }
        set {
            settings.dxvkConfig.dxvkHud = newValue
        }
    }

    public var name: String {
        get {
            return settings.info.name
        } set {
            settings.info.name = newValue
        }
    }

    public var shortcuts: [Shortcut] {
        get {
            return settings.info.shortcuts
        }
        set {
            settings.info.shortcuts = newValue
        }
    }

    public init(bottleURL: URL) {
        bottleUrl = bottleURL
        metadataUrl = bottleURL
            .appending(path: "Metadata")
            .appendingPathExtension("plist")
        settings = .init()
        if !decode() {
            encode()
        }
    }

    @discardableResult
    private func decode() -> Bool {
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
                encode()
            }
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    private func encode() -> Bool {
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

    public func environmentVariables(environment: inout [String: String]) {
        if dxvk {
            environment.updateValue("dxgi,d3d9,d3d10core,d3d11=n,b", forKey: "WINEDLLOVERRIDES")
            switch dxvkHud {
            case .full:
                environment.updateValue("full", forKey: "DXVK_HUD")
            case .partial:
                environment.updateValue("devinfo,fps,frametimes", forKey: "DXVK_HUD")
            case .fps:
                environment.updateValue("fps", forKey: "DXVK_HUD")
            case .off:
                break
            }
        }

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
