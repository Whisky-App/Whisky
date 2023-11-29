//
//  UpdateControlerView.swift
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

import SwiftUI
import Sparkle

enum UpdateState {
    case initializating, downloading, extracting, installing
}

struct UpdateControlerView: View {
    let updater: SPUUpdater

    @State var showCheckingForUpdates = false
    @State var cancelCheckingForUpdates: (() -> Void)?
    @State var showUpdatePreview = false
    @State var updateUltimatum: ((Bool) -> Void)?
    @State var showUpdater = false
    @State var updateState: UpdateState = .initializating
    @State var updateStateDownloadStatedAt: Date = Date.init(timeIntervalSince1970: 0)
    @State var updateStateDownloadableBytes: Double = 0
    @State var updateStateDownloadedBytes: Double = 0
    @State var updateStateExtractProgress: Double = 0

    var body: some View {
        VStack {}
            .sheet(isPresented: $showCheckingForUpdates, content: {
                UpdateCheckingView(cancel: {
                    showCheckingForUpdates = false
                    cancelCheckingForUpdates?()
                })
                    .frame(width: 300)
                    .interactiveDismissDisabled()
            })
             .sheet(isPresented: $showUpdatePreview, content: {
                UpdatePreviewView(dismiss: {
                    showUpdatePreview = false
                    updateUltimatum?(false)
                    updateUltimatum = .none
                }, install: {
                    updateUltimatum?(true)
                    updateUltimatum = .none
                })
                    .interactiveDismissDisabled()
                    .frame(width: 600, height: 400)
            })
            .sheet(isPresented: $showUpdater, content: {
                UpdateInstallingView(
                    state: $updateState,
                    downloadStatedAt: $updateStateDownloadStatedAt,
                    downloadableBytes: $updateStateDownloadableBytes,
                    downloadedBytes: $updateStateDownloadedBytes,
                    extractProgress: $updateStateExtractProgress
                )
                    .interactiveDismissDisabled()
                    .frame(width: 300)
            })
            .onAppear {
                // On fn called show sheet
                SparkleUpdaterEvents.shared.checkingForUpdates = { cancel in
                    // Prevent updater from checking for updates
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = false
                    cancelCheckingForUpdates = {
                        cancel()
                    }
                    showCheckingForUpdates = true
                }
                SparkleUpdaterEvents.shared.updateFound = { _, _, reply in
                    showCheckingForUpdates = false
                    showUpdater = false
                    showUpdatePreview = false
                    updateUltimatum = { option in
                        if option {

                            reply(.install)
                        } else {
                            reply(.dismiss)
                        }
                    }
                    showUpdatePreview = true
                }
                SparkleUpdaterEvents.shared.updateDismiss = {
                    // Show Alert
                    if showCheckingForUpdates {
                        showCheckingForUpdates = false
                        showUpdatePreview = false
                        showUpdater = false
                        // no update found
                        displayPrompt(
                            title: String(localized: "update.noUpdateFound"),
                            description: String(localized: "update.noUpdateFound.description"),
                            action: String(localized: "button.ok"),
                            actionHandler: {
                                // Dismiss
                            }
                        )
                    }
                }
                SparkleUpdaterEvents.shared.updateError = { error in
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = false
                    displayPrompt(
                        title: String(localized: "update.error"),
                        description: error.localizedDescription,
                        action: String(localized: "button.ok"),
                        actionHandler: {
                            // Dismiss
                        }
                    )
                }
                // Update download state
                SparkleUpdaterEvents.shared.updateDownloadState = {
                    if updateStateDownloadStatedAt == Date(timeIntervalSince1970: 0) {
                        updateStateDownloadStatedAt = Date()
                    }
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = true
                    withAnimation { updateState = .downloading }
                    updateStateDownloadableBytes = SparkleUpdaterEvents.shared.expectedContentLength
                    updateStateDownloadedBytes = SparkleUpdaterEvents.shared.receivedContentLength
                }
                // Update extract state
                SparkleUpdaterEvents.shared.updateExtractState = {
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = true
                    withAnimation { updateState = .extracting }
                    updateStateExtractProgress = SparkleUpdaterEvents.shared.extractProgress
                }
                // Update install state
                SparkleUpdaterEvents.shared.updateInstallState = {
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = true
                    withAnimation { updateState = .installing }
                }
                // Update ready relaunch
                SparkleUpdaterEvents.shared.updateReadyRelaunch = { relaunch in
                    showCheckingForUpdates = false
                    showUpdatePreview = false
                    showUpdater = false
                    WhiskyApp.killBottles()
                    // Actualy relaunch (I don't want to make a helper for this so.... you get...)
                    let task = Process()
                    task.launchPath = "/bin/sh"
                    task.arguments = [
                        "-c",
                        """
                        kill "\(ProcessInfo.processInfo.processIdentifier)";
                        sleep 0.5; open "\(Bundle.main.bundlePath)"
                        """
                    ]
                    task.launch()
                    // Relaunch
                    relaunch(.install)
                    NSApp.terminate(nil)
                    exit(0)
                }
            }
    }

    func displayPrompt(title: String, description: String, action: String, actionHandler: @escaping () -> Void) {
    showCheckingForUpdates = false
        showUpdatePreview = false
        showUpdater = false
        Task(priority: .userInitiated) {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = title
                alert.informativeText = description
                alert.addButton(withTitle: action)
                alert.runModal()
                            }
        }
    }
}

struct UpdateCheckingView: View {
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("update.checkingForUpdates")
                .fontWeight(.bold)
            ProgressView()
                .progressViewStyle(.linear)
            HStack {
                Spacer()
                Button("button.cancel") {
                    cancel()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(alignment: .leading)
    }
}

struct UpdateInstallingView: View {
    @Binding var state: UpdateState
    @Binding var downloadStatedAt: Date
    @Binding var downloadableBytes: Double
    @Binding var downloadedBytes: Double
    @Binding var extractProgress: Double

    @State var fractionProgress: Double = 0
    @State var downloadSpeed: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                state == .downloading
                    ? "update.downloading"
                    : state == .extracting
                    ? "update.extracting"
                    : state == .installing
                    ? "update.installing"
                    : "update.initializating"
            )
                .fontWeight(.bold)
            if state == .installing || state == .initializating {
                ProgressView()
                    .progressViewStyle(.linear)
            } else {
                ProgressView(value: fractionProgress, total: 1)
                    .progressViewStyle(.linear)
                if state == .downloading {
                    HStack {
                        HStack {
                            Text(String(format: String(localized: "setup.gptk.progress"),
                                        formatBytes(bytes: downloadedBytes),
                                        formatBytes(bytes: downloadableBytes)))
                            + Text(String(" "))
                            + (shouldShowEstimate() ?
                               Text(String(format: String(localized: "setup.gptk.eta"),
                                           formatRemainingTime(remainingBytes: downloadableBytes - downloadedBytes)))
                               : Text(String()))
                            Spacer()
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                    }
                }
            }
        }
        .padding(20)
        .frame(alignment: .leading)
        .onChange(of: downloadedBytes) {
            let currentTime = Date()
            let elapsedTime = currentTime.timeIntervalSince(downloadStatedAt ?? currentTime)
            if downloadedBytes > 0 {
                downloadSpeed = Double(downloadedBytes) / elapsedTime
            }
            withAnimation {
                if downloadableBytes > 0 {
                    fractionProgress = downloadedBytes / downloadableBytes
                } else {
                    fractionProgress = 0
                }
            }
        }
        .onChange(of: extractProgress) {
            withAnimation {
                fractionProgress = extractProgress
            }
        }
    }

    func formatBytes(bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func shouldShowEstimate() -> Bool {
        let elapsedTime = Date().timeIntervalSince(downloadStatedAt ?? Date())
        return Int(elapsedTime.rounded()) > 5 && downloadedBytes != 0
    }

    func formatRemainingTime(remainingBytes: Double) -> String {
        let remainingTimeInSeconds = remainingBytes / downloadSpeed

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        if shouldShowEstimate() {
            return formatter.string(from: TimeInterval(remainingTimeInSeconds)) ?? ""
        } else {
            return ""
        }
    }
}
