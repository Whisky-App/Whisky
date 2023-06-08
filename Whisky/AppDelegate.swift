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
        if !hasShownMoveToApplicationsAlert {
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

    private func showAlertOnFirstLaunch() {
        let alert = NSAlert()
        alert.messageText = "Would you like to move Whisky to your Applications folder?"
        alert.informativeText = "In some cases app couldn't function properly from Downloads folder"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Don't Move")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let fileManager = FileManager.default
            let appURL = Bundle.main.bundleURL

            guard let applicationsURL = fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first else {
                return
            }

            let destinationURL = applicationsURL.appendingPathComponent(appURL.lastPathComponent)
            do {
                _ = try fileManager.replaceItemAt(destinationURL, withItemAt: appURL)

                NSWorkspace.shared.open(destinationURL)
            } catch {
                print("Failed to move the app: \(error)")
            }
        }
    }
}
