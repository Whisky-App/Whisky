//
//  Program.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation
import AppKit
import QuickLookThumbnailing

public class Program: Hashable {
    public static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }

    var name: String
    var url: URL

    var arguments: [String: String] = [:]

    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}
