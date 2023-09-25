//
//  ProgramSettings.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 06/04/2023.
//

import Foundation

public enum Locales: String, Codable, CaseIterable {
    case auto = ""
    case german = "de_DE.UTF-8"
    case english = "en_US"
    case spanish = "es_ES.UTF-8"
    case french = "fr_FR.UTF-8"
    case italian = "it_IT.UTF-8"
    case japanese = "ja_JP.UTF-8"
    case korean = "ko_KR.UTF-8"
    case russian = "ru_RU.UTF-8"
    case ukranian = "uk_UA.UTF-8"
    case thai = "th_TH.UTF-8"
    case chineseSimplified = "zh_CN.UTF-8"
    case chineseTraditional = "zh_TW.UTF-8"

    // swiftlint:disable:next cyclomatic_complexity
    public func pretty() -> String {
        switch self {
        case .auto:
            return String(localized: "locale.auto")
        case .german:
            return "Deutsch"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .italian:
            return "Italiano"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .russian:
            return "Русский"
        case .ukranian:
            return "Українська"
        case .thai:
            return "ไทย"
        case .chineseSimplified:
            return "简体中文"
        case .chineseTraditional:
            return "繁體中文"
        }
    }
}

public struct ProgramSettingsData: Codable {
    var locale: Locales = .auto
    var environment: [String: String] = [:]
    var arguments: String = ""
}

public class ProgramSettings {
    public var settings: ProgramSettingsData {
        didSet {
            encode()
        }
    }

    public var locale: Locales {
        get {
            return settings.locale
        }
        set {
            settings.locale = newValue
        }
    }

    public var environment: [String: String] {
        get {
            return settings.environment
        }
        set {
            settings.environment = newValue
        }
    }

    public var arguments: String {
        get {
            return settings.arguments
        }
        set {
            settings.arguments = newValue
        }
    }

    let settingsUrl: URL

    init(bottleUrl: URL, name: String) {
        let settingsFolder = bottleUrl.appending(path: "Program Settings")
        self.settingsUrl = settingsFolder
                                    .appending(path: name)
                                    .appendingPathExtension("plist")

        if !FileManager.default.fileExists(atPath: settingsFolder.path(percentEncoded: false)) {
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

        // Dirty 'fix' for Steam with DXVK
        if name.contains("steam") {
            environment["WINEDLLOVERRIDES"] = "dxgi,d3d9,d3d10core,d3d11=b"
        }
    }

    @discardableResult
    private func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(ProgramSettingsData.self, from: data)
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
            try data.write(to: settingsUrl)
            return true
        } catch {
            return false
        }
    }
}
