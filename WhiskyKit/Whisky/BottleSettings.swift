//
//  BottleSettings.swift
//  WhiskyKit
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

public struct PinnedProgram: Codable, Hashable {
    public var name: String
    public var url: URL

    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

public struct BottleInfo: Codable {
    var name: String = "Bottle"
    var pins: [PinnedProgram] = []
    var blocklist: [URL] = []
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
    var dxvkAsync: Bool = true
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

    public var dxvkAsync: Bool {
        get {
            return settings.dxvkConfig.dxvkAsync
        } set {
            settings.dxvkConfig.dxvkAsync = newValue
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

    public var pins: [PinnedProgram] {
        get {
            return settings.info.pins
        }
        set {
            settings.info.pins = newValue
        }
    }

    public var blocklist: [URL] {
        get {
            return settings.info.blocklist
        }
        set {
            settings.info.blocklist = newValue
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

    public func environmentVariables(wineEnv: inout [String: String]) {
        if dxvk {
            wineEnv.updateValue("dxgi,d3d9,d3d10core,d3d11=n,b", forKey: "WINEDLLOVERRIDES")
            switch dxvkHud {
            case .full:
                wineEnv.updateValue("full", forKey: "DXVK_HUD")
            case .partial:
                wineEnv.updateValue("devinfo,fps,frametimes", forKey: "DXVK_HUD")
            case .fps:
                wineEnv.updateValue("fps", forKey: "DXVK_HUD")
            case .off:
                break
            }
        }

        if dxvkAsync {
            wineEnv.updateValue("1", forKey: "DXVK_ASYNC")
        }

        if esync {
            wineEnv.updateValue("1", forKey: "WINEESYNC")
        }

        if metalHud {
            wineEnv.updateValue("1", forKey: "MTL_HUD_ENABLED")
        }

        if metalTrace {
            wineEnv.updateValue("1", forKey: "METAL_CAPTURE_ENABLED")
        }
    }
}
