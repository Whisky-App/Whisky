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

public class Program: Hashable {
    public static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }

    public var name: String
    public var url: URL
    public var settings: ProgramSettings
    public var bottle: Bottle
    public var pinned: Bool
    public var peFile: PEFile?

    public init(name: String, url: URL, bottle: Bottle) {
        self.name = name
        self.url = url
        self.bottle = bottle
        self.settings = ProgramSettings(bottleUrl: bottle.url, name: name)
        self.pinned = bottle.settings.pins.contains(where: { $0.url == url })
        do {
            self.peFile = try PEFile(handle: FileHandle(forReadingFrom: url))
        } catch {
            self.peFile = nil
        }
    }

    public func generateEnvironment() -> [String: String] {
        var environment = settings.environment
        if settings.locale != .auto {
            environment.updateValue(settings.locale.rawValue, forKey: "LC_ALL")
        }
        return environment
    }
}
