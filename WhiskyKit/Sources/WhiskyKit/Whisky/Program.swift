//
//  Program.swift
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

// swiftlint:disable:next todo
// TODO: Should not be unchecked!
public final class Program: ObservableObject, Equatable, Hashable, Identifiable, @unchecked Sendable {
    public let bottle: Bottle
    public let url: URL
    public let settingsURL: URL

    public var name: String {
        url.lastPathComponent
    }

    @Published public var settings: ProgramSettings {
        didSet { saveSettings() }
    }

    @Published public var pinned: Bool {
        didSet {
            if pinned {
                bottle.settings.pins.append(PinnedProgram(
                    name: name.replacingOccurrences(of: ".exe", with: ""),
                    url: url
                ))
            } else {
                bottle.settings.pins.removeAll(where: { $0.url == url })
            }
        }
    }

    public let peFile: PEFile?

    public init(url: URL, bottle: Bottle) {
        let name = url.lastPathComponent
        self.bottle = bottle
        self.url = url
        self.pinned = bottle.settings.pins.contains(where: { $0.url == url })

        // Warning: This will break if two programs share the same name such as "Launch.exe"
        // Best to add some sort of UUID in the path or file
        let settingsFolder = bottle.url.appending(path: "Program Settings")
        let settingsUrl = settingsFolder.appending(path: name).appendingPathExtension("plist")
        self.settingsURL = settingsUrl

        do {
            if !FileManager.default.fileExists(atPath: settingsFolder.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: settingsFolder, withIntermediateDirectories: true)
            }

            self.settings = try ProgramSettings.decode(from: settingsUrl)
        } catch {
            Logger.wineKit.error("Failed to load settings for `\(name)`: \(error)")
            self.settings = ProgramSettings()
        }

        do {
            self.peFile = try PEFile(url: url)
        } catch {
            self.peFile = nil
        }
    }

    public func generateEnvironment() -> [String: String] {
        var environment = settings.environment
        if settings.locale != .auto {
            environment["LC_ALL"] = settings.locale.rawValue
        }
        return environment
    }

    /// Save the settings to file
    private func saveSettings() {
        do {
            try settings.encode(to: settingsURL)
        } catch {
            Logger.wineKit.error("Failed to save settings for `\(self.name)`: \(error)")
        }
    }

    // MARK: - Equatable

    public static func == (lhs: Program, rhs: Program) -> Bool {
        return lhs.url == rhs.url
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }

    // MARK: - Identifiable

    public var id: URL {
        self.url
    }
}
