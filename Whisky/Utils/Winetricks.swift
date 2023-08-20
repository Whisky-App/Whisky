//
//  Winetricks.swift
//  Whisky
//
//  Created by Isaac Marovitz on 12/07/2023.
//

import Foundation
import AppKit

class Winetricks {
    static let winetricksPath = WineInstaller.libraryFolder.appending(path: "winetricks")

    static func isWinetricksInstalled() -> Bool {
        return true // because we will install it ourselves anyway, who cares.
    }

    @discardableResult
    static func getWinetricks() -> Bool {
        guard let url = URL(string:
                                "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks") else {
            return false
        }

        guard let data = try? Data(contentsOf: url) else {
            return false
        }

        do {
            try data.write(to: winetricksPath)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: winetricksPath.path)
        } catch {
            return false
        }

        return true
    }

    static func runCommand(command: String, bottle: Bottle) async {
        getWinetricks()
        // swiftlint:disable:next line_length
        let winetricksCmd = #"PATH=\"\#(Wine.binFolder.path):$PATH\" WINE=wine64 WINEPREFIX=\"\#(bottle.url.path)\" '\#(winetricksPath.path)' \#(command)"#

        let script = """
        tell application "Terminal"
            activate
            do script "\(winetricksCmd)"
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
                            + " \(command): "
                            + description
                        alert.alertStyle = .critical
                        alert.addButton(withTitle: String(localized: "button.ok"))
                        alert.runModal()
                    }
                }
            }
        }
    }
}
