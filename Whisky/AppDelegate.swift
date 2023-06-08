//
//  AppDelegate.swift
//  Whisky
//
//  Created by Viacheslav Shkliarov on 08.06.2023.
//

import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("hasShownMoveToApplicationsAlert") private var hasShownMoveToApplicationsAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if !hasShownMoveToApplicationsAlert && !AppDelegate.insideAppsFolder {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                NSApp.activate(ignoringOtherApps: true)
                self.showAlertOnFirstLaunch()
                self.hasShownMoveToApplicationsAlert = true
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        WhiskyApp.killBottles()
    }

    private static var appUrl: URL? {
        Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
    }

    private static var expectedUrl = URL(fileURLWithPath: "/Applications/Whisky.app")

    private static var insideAppsFolder: Bool {
        if let url = appUrl {
            return url.path.contains("Xcode") || url.path.contains(expectedUrl.path)
        }
        return false
    }

    private func showAlertOnFirstLaunch() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("showAlertOnFirstLaunch.messageText", comment: "")
        alert.informativeText = NSLocalizedString("showAlertOnFirstLaunch.informativeText", comment: "")
        alert.addButton(withTitle: NSLocalizedString("showAlertOnFirstLaunch.button.moveToApplications", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("showAlertOnFirstLaunch.button.dontMove", comment: ""))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let appURL = Bundle.main.bundleURL

            do {
                _ = try FileManager.default.replaceItemAt(AppDelegate.expectedUrl, withItemAt: appURL)
                NSWorkspace.shared.open(AppDelegate.expectedUrl)
            } catch {
                print("Failed to move the app: \(error)")
            }
        }
    }
}
