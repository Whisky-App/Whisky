//
//  BottleSettings.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation

struct BottleSettingsData: Codable {
    var wineVersion: String = "8.4"
    var windowsVersion: WinVersion = .win7
    var dxvk: Bool = false
    var dxvkHud: Bool = false
    var metalHud: Bool = false
    var esync: Bool = false
}

class BottleSettings {
    var settings: BottleSettingsData {
        didSet {
            encode()
        }
    }

    let settingsUrl: URL

    init(bottleUrl: URL, name: String) {
        self.settingsUrl = bottleUrl.appendingPathComponent(name)
                                    .appendingPathExtension("plist")

        settings = BottleSettingsData()
        if !decode() {
            encode()
        }
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode(BottleSettingsData.self, from: data)
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
