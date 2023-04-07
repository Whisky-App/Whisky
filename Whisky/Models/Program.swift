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
    var settings: ProgramSettings
    var bottle: Bottle

    init(name: String, url: URL, bottle: Bottle) {
        self.name = name
        self.url = url
        self.bottle = bottle
        self.settings = ProgramSettings(bottleUrl: bottle.url, name: name)
    }

    func run() async {
        do {
            try await Wine.runProgram(program: self)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("alert.message", comment: "")
                alert.informativeText = NSLocalizedString("alert.info", comment: "")
                    + " \(url.lastPathComponent): "
                    + error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: NSLocalizedString("button.ok", comment: ""))
                alert.runModal()
            }
        }
    }
}
