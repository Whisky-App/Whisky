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

public class Bottle: Hashable, Identifiable {
    public static func == (lhs: Bottle, rhs: Bottle) -> Bool {
        return lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }
    public var id: URL {
        self.url
    }

    public var url: URL
    public var settings: BottleSettings
    public var programs: [Program] = []
    public var inFlight: Bool = false

    public init(bottleUrl: URL, inFlight: Bool = false) {
        self.settings = BottleSettings(bottleURL: bottleUrl)
        self.url = bottleUrl
        self.inFlight = inFlight
    }
}

extension Array where Element == Bottle {
    public mutating func sortByName() {
        self.sort { $0.settings.name.lowercased() < $1.settings.name.lowercased() }
    }
}
