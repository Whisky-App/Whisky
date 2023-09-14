//
//  Program.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import Foundation
import AppKit
import WhiskyKit

extension Program {
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

    func generateTerminalCommand() -> String {
        var wineCmd = "\(Wine.wineBinary.esc) start /unix \(url.esc) \(settings.arguments)"

        let env = Wine.constructEnvironment(bottle: bottle,
                                            environment: settings.environment)
        for environment in env {
            wineCmd = "\(environment.key)=\(environment.value) " + wineCmd
        }

        return wineCmd
    }

    func runInTerminal() async {
        let wineCmd = generateTerminalCommand().replacingOccurrences(of: "\\", with: "\\\\")

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
