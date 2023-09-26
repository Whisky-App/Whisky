//
//  Program.swift
//  Whisky
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
                                            programEnv: generateEnvironment())
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

    func togglePinned() -> Bool {
        if pinned {
            bottle.settings.pins.removeAll(where: { $0.url == url })
            pinned = false
        } else {
            bottle.settings.pins.append(PinnedProgram(name: name
                                                            .replacingOccurrences(of: ".exe", with: ""),
                                                      url: url))
            pinned = true
        }

        return pinned
    }
}
