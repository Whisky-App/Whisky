//
//  SparkleUpdaterEvents.swift
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
import Sparkle

class SparkleUpdaterEvents: NSObject, SPUUserDriver {
    static let shared = SparkleUpdaterEvents()

    var checkingForUpdates: ((@escaping () -> Void) -> Void)?
    var updateFound: ((SUAppcastItem, SPUUserUpdateState, @escaping (SPUUserUpdateChoice) -> Void) -> Void)?
    var update: ((SPUDownloadData) -> Void)?
    var updateError: ((NSError) -> Void)?
    var updateDownloadState: (() -> Void)?
    var updateExtractState: (() -> Void)?
    var updateInstallState: (() -> Void)?
    var updateReadyRelaunch: ((@escaping (SPUUserUpdateChoice) -> Void) -> Void)?
    var updateDismiss: (() -> Void)?

    var expectedContentLength: Double = 0
    var receivedContentLength: Double = 0

    var extractProgress: Double = 0

    enum UpdateOption {
        case install, dismiss
    }

    func show(_ request: SPUUpdatePermissionRequest) async -> SUUpdatePermissionResponse {
        return .init(
            automaticUpdateChecks: false,
            sendSystemProfile: false
        )
    }

    func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        checkingForUpdates?(cancellation)
    }

    func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
    ) {
        if let updateFound = updateFound {
            updateFound(appcastItem, state, reply)
        } else {
            reply(.dismiss)
        }
    }

    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        update?(downloadData)
    }

    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        updateError?(error as NSError)
    }

    func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        updateError?(error as NSError)

        acknowledgement()
    }

    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        updateError?(error as NSError)

        acknowledgement()
    }

    func showDownloadInitiated(cancellation: @escaping () -> Void) {
        updateDownloadState?()
    }

    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        self.expectedContentLength = Double(expectedContentLength)
        updateDownloadState?()
    }

    func showDownloadDidReceiveData(ofLength length: UInt64) {
        receivedContentLength += Double(length)
        updateDownloadState?()
    }

    func showDownloadDidStartExtractingUpdate() {
        updateExtractState?()
    }

    func showExtractionReceivedProgress(_ progress: Double) {
        extractProgress = progress
        updateExtractState?()
    }

    func showReady(toInstallAndRelaunch acknowledgement: @escaping (SPUUserUpdateChoice) -> Void) {
        updateReadyRelaunch?(acknowledgement)
    }

    func showInstallingUpdate(
        withApplicationTerminated applicationTerminated: Bool,
        retryTerminatingApplication: @escaping () -> Void
    ) {
        updateInstallState?()
    }

    func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        acknowledgement()
    }

    func showUpdateInFocus() {
        return
    }

    func dismissUpdateInstallation() {
        updateDismiss?()
        return
    }
}
