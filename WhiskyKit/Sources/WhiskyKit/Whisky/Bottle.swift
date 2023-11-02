//
//  Bottle.swift
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
import SwiftUI
import os.log

public class Bottle: Hashable, Identifiable, ObservableObject {
    public static func == (lhs: Bottle, rhs: Bottle) -> Bool {
        return lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }
    public var id: URL {
        self.url
    }

    public let url: URL
    private let metadataURL: URL
    @Published public var settings: BottleSettings {
        didSet { saveSettings() }
    }
    @Published public var programs: [Program] = []
    public var inFlight: Bool = false
    public var isActive: Bool = false

    public init(bottleUrl: URL, inFlight: Bool = false, isActive: Bool = false) {
        let metadataURL = bottleUrl.appending(path: "Metadata").appendingPathExtension("plist")
        self.url = bottleUrl
        self.inFlight = inFlight
        self.isActive = isActive
        self.metadataURL = metadataURL

        do {
            self.settings = try BottleSettings.decode(from: metadataURL)
        } catch {
            Logger.wineKit.error(
              "Failed to load settings for bottle `\(metadataURL.path(percentEncoded: false))`: \(error)"
            )
            self.settings = BottleSettings()
        }
    }

    /// Encode and save the bottle settings
    private func saveSettings() {
        do {
            try settings.encode(to: self.metadataURL)
        } catch {
            Logger.wineKit.error(
                "Failed to encode settings for bottle `\(self.metadataURL.path(percentEncoded: false))`: \(error)"
            )
        }
    }
}

extension Array where Element == Bottle {
    public mutating func sortByName() {
        self.sort { $0.settings.name.lowercased() < $1.settings.name.lowercased() }
    }
    public mutating func sortByActive() {
        self.sort { $0.isActive && !$1.isActive }
    }
}
