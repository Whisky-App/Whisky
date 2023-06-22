//
//  ConvertFormat.swift
//  Whisky
//
//  Created by Josh on 6/21/23.
//

import Foundation

struct LegacyShortcut: Decodable {
    let name: String
    let link: URL
}

private struct LegacyBottleFormat: Decodable {
    let wineVersion: String
    let windowsVersion: WinVersion
    let metalHud: Bool
    let metalTrace: Bool
    let esync: Bool
    let url: URL
    var shortcuts: [LegacyShortcut]?
}

func convertFormat(plistPath: URL) -> URL? {
    do {
        let decoder = PropertyListDecoder()
        let data = try Data(contentsOf: plistPath)
        let plist = try decoder.decode(LegacyBottleFormat.self, from: data)
        // Create new settings
        let settings = BottleSettings.init(bottleURL: plist.url)
        settings.name = plistPath.deletingPathExtension().lastPathComponent
        settings.wineVersion = try Semver.parse(data: plist.wineVersion)
        settings.windowsVersion = plist.windowsVersion
        settings.metalHud = plist.metalHud
        settings.metalTrace = plist.metalTrace
        settings.esync = plist.esync
        settings.shortcuts = []
        plist.shortcuts?.forEach({
            settings.shortcuts.append(.init(name: $0.name, link: $0.link))
        })
        // It should not need this but just in case
        settings.encode()
        // Remove plist
        try FileManager.default.removeItem(at: plistPath)
        return .some(plist.url)
    } catch {
        print("Failed to convert: \(error)")
        return .none
    }
}
