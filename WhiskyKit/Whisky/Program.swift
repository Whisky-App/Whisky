//
//  Program.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 14/09/2023.
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
        self.pinned = bottle.settings.shortcuts.contains(where: { $0.link == url })
        do {
            self.peFile = try PEFile(data: Data(contentsOf: url))
        } catch {
            self.peFile = nil
        }
    }
}
