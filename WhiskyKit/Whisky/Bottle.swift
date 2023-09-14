//
//  Bottle.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 14/09/2023.
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
    public var startMenuPrograms: [ShellLinkHeader] = []
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
