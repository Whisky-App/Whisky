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

class SparkleUpdaterEvents: NSObject, SPUUserDriver, ObservableObject {
    static let shared = SparkleUpdaterEvents()

    enum UpdaterState {
        case idle, error, checking, updateFound, updateNotFound, initializing,
             downloading, extracting, installing, readyToRelaunch
    }

    enum UpdateOption {
        case install, dismiss
    }

    @Published var state: UpdaterState = .idle
    @Published var downloadBytesTotal: Double = 0
    @Published var downloadBytesReceived: Double = 0
    @Published var extractProgress: Double = 0

    // Errors
    var errorData: NSError?
    private var errorAcknowledgementCallback: (() -> Void)?

    // Checking for updates
    private var checkingForUpdatesCancellationCallback: (() -> Void)?

    // Update found
    var appcastItem: SUAppcastItem?
    private var updateFoundActionCallback: ((SPUUserUpdateChoice) -> Void)?

    // Downloading
    var downloadStartedAt: Date?
    private var downloadingCancellationCallback: (() -> Void)?

    // Ready to relaunch
    private var updateReadyRelaunchCallback: ((SPUUserUpdateChoice) -> Void)?

    /// Clear all callbacks
    private func clearCallbacks() {
        self.checkingForUpdatesCancellationCallback = .none
        self.updateFoundActionCallback = .none
        self.downloadingCancellationCallback = .none
        self.updateReadyRelaunchCallback = .none
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func show(_ request: SPUUpdatePermissionRequest) async -> SUUpdatePermissionResponse {
        return .init(
            automaticUpdateChecks: false,
            sendSystemProfile: false
        )
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        state = .checking
        self.checkingForUpdatesCancellationCallback = cancellation
    }

    /// Cancel the update check
    func cancelUpdateCheck() {
        self.checkingForUpdatesCancellationCallback?()
        clearCallbacks()
        self.state = .idle
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateFound(
        with appcastItem: SUAppcastItem,
        state: SPUUserUpdateState,
        reply: @escaping (SPUUserUpdateChoice) -> Void
    ) {
        clearCallbacks()
        self.appcastItem = appcastItem
        self.updateFoundActionCallback = reply
        self.state = .updateFound
    }

    /// Call to tell sparkle to download / dissmiss the update
    func shouldUpdate(_ action: UpdateOption) {
        guard let callback = self.updateFoundActionCallback else { return }
        switch action {
        case .install:
            callback(.install)
            self.state = .initializing
        case .dismiss:
            callback(.dismiss)
            self.state = .idle
        }
        // Reset callback
        clearCallbacks()
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        // Never needed
        return
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        clearCallbacks()
        self.errorData = error as NSError
        self.state = .error
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        clearCallbacks()
        self.errorData = error as NSError
        self.errorAcknowledgementCallback = acknowledgement
        self.state = .error
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        clearCallbacks()
        self.errorData = error as NSError
        self.errorAcknowledgementCallback = acknowledgement
        self.state = .error
    }

    /// Acknowledgement of the error
    func errorAcknowledgement() {
        self.errorAcknowledgementCallback?()
        clearCallbacks()
        self.errorData = .none
        self.state = .idle
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showDownloadInitiated(cancellation: @escaping () -> Void) {
        clearCallbacks()
        self.downloadStartedAt = Date()
        self.downloadingCancellationCallback = cancellation
        self.state = .downloading
    }

    /// Cancel the download
    func cancelDownload() {
        self.downloadingCancellationCallback?()
        // Reset download
        clearCallbacks()
        self.downloadBytesTotal = 0
        self.downloadBytesReceived = 0
        self.downloadStartedAt = .none
        self.state = .idle
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        self.downloadBytesTotal = Double(expectedContentLength)
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showDownloadDidReceiveData(ofLength length: UInt64) {
        self.downloadBytesReceived += Double(length)
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showDownloadDidStartExtractingUpdate() {
        clearCallbacks()
        // Reset download
        self.downloadBytesTotal = 0
        self.downloadBytesReceived = 0
        self.downloadStartedAt = .none
        self.state = .extracting
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showExtractionReceivedProgress(_ progress: Double) {
        self.extractProgress = progress
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        clearCallbacks()
        self.updateReadyRelaunchCallback = reply
        self.state = .readyToRelaunch
    }

    /// Call to tell sparkle to install the update
    func relaunch(_ action: UpdateOption) {
        guard let callback = self.updateReadyRelaunchCallback else { return }
        switch action {
        case .install:
            callback(.install)
            self.state = .installing
        case .dismiss:
            callback(.dismiss)
            self.state = .idle
        }
        // Reset callback
        clearCallbacks()
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showInstallingUpdate(
        withApplicationTerminated applicationTerminated: Bool,
        retryTerminatingApplication: @escaping () -> Void
    ) {
        clearCallbacks()
        // Reset extract
        self.extractProgress = 0
        self.state = .installing
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        clearCallbacks()
        // Never used
        acknowledgement()
        return
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func showUpdateInFocus() {
        // Never needed
        return
    }

    /// Implementation of `SPUUserDriver` protocol
    internal func dismissUpdateInstallation() {
        // If it is in the checking state, it means that there is no update available
        if self.state == .checking {
            clearCallbacks()
            self.state = .updateNotFound
        }
    }
}
