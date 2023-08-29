//
//  Program.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation
import AppKit

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
    private(set) var favourited: Bool

    init(name: String, url: URL, bottle: Bottle) {
        self.name = name
        self.url = url
        self.bottle = bottle
        self.settings = ProgramSettings(bottleUrl: bottle.url, name: name)
        self.favourited = bottle.settings.shortcuts.contains(where: { $0.link == url })
    }

    func run() async {
        if NSEvent.modifierFlags.contains(.shift) {
            print("Running in terminal...")
            await runInTerminal()
        } else {
            await runInWine()
        }
    }

    func runInWine() async {
        do {
            try await Wine.runProgram(program: self)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = String(localized: "alert.message")
                alert.informativeText = String(localized: "alert.info")
                    + " \(url.lastPathComponent): "
                    + error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: String(localized: "button.ok"))
                alert.runModal()
            }
        }
    }

    func runInTerminal() async {
        var wineCmd = "\(Wine.wineBinary.esc) start /unix \(url.esc) \(settings.arguments)"

        let env = Wine.constructEnvironment(bottle: bottle,
                                            environment: settings.environment)
        for environment in env {
            wineCmd = "\(environment.key)=\(environment.value) " + wineCmd
        }

        wineCmd = wineCmd.replacingOccurrences(of: "\\", with: "\\\\")

        let script = """
        tell application "Terminal"
            activate
            do script "\(wineCmd)"
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)

            if let error = error {
                print(error)
                if let description = error["NSAppleScriptErrorMessage"] as? String {
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "alert.message")
                        alert.informativeText = String(localized: "alert.info")
                            + " \(url.lastPathComponent): "
                            + description
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: String(localized: "button.ok"))
                        alert.runModal()
                    }
                }
            }
        }
    }

    func toggleFavourited() -> Bool {
        if favourited {
            bottle.settings.shortcuts.removeAll(where: { $0.link == url })
            favourited = false
        } else {
            bottle.settings.shortcuts.append(Shortcut(name: name, link: url))
            favourited = true
        }

        return favourited
    }
}
