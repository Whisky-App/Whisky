//
//  WhiskyCmd.swift
//  Whisky
//
//  Created by Isaac Marovitz on 26/08/2023.
//

import Foundation
import AppKit

class WhiskyCmd {
	static func install() async {
		let whiskyCmdURL = Bundle.main.url(forResource: "WhiskyCmd", withExtension: nil)

		if let whiskyCmdURL = whiskyCmdURL {
			// swiftlint:disable line_length
			let script = """
			do shell script "ln -s \(whiskyCmdURL.path(percentEncoded: false)) /usr/local/bin/whisky" with administrator privileges
			"""
			// swiftlint:enable line_length

			var error: NSDictionary?
			// Use AppleScript because somehow in 2023 Apple doesn't have good privileged file ops APIs
			if let appleScript = NSAppleScript(source: script) {
				appleScript.executeAndReturnError(&error)

				if let error = error {
					print(error)
					if let description = error["NSAppleScriptErrorMessage"] as? String {
						await MainActor.run {
							let alert = NSAlert()
							alert.messageText = String(localized: "alert.message")
							alert.informativeText = String(localized: "alert.info")
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
}
