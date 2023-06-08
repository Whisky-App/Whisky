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
        alert.messageText = NSLocalizedString("showAlertOnFirstLaunch.messageText", comment: "")
        alert.informativeText = NSLocalizedString("showAlertOnFirstLaunch.informativeText", comment: "")
        alert.addButton(withTitle: NSLocalizedString("showAlertOnFirstLaunch.button.moveToApplications", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("showAlertOnFirstLaunch.button.dontMove", comment: ""))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let appURL = Bundle.main.bundleURL

            guard let applicationsURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first else {
                return
            }

            let destinationURL = applicationsURL.appendingPathComponent(appURL.lastPathComponent)
            do {
                _ = try FileManager.default.replaceItemAt(destinationURL, withItemAt: appURL)
                NSWorkspace.shared.open(destinationURL)
            } catch {
                print("Failed to move the app: \(error)")
            }
        }
    }
}
