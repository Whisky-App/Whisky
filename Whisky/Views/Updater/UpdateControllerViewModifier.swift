//
//  UpdateControllerViewModifier.swift
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

extension View {
    func updateController() -> some View {
        return modifier(UpdateControllerViewModifier())
    }
}

struct UpdateControllerViewModifier: ViewModifier {
    @State private var sheetCheckingUpdateViewPresented = false
    @State private var sheetUpdateNotFoundViewPresented = false
    @State private var sheetChangeLogViewPresented = false
    @State private var sheetUpdateInstallingViewPresented = false
    @State private var sheetUpdateReadyToRelaunchViewPresented = false
    @State private var sheetUpdateErrorViewPresented = false
    @ObservedObject private var updater = SparkleUpdaterEvents.shared

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $sheetCheckingUpdateViewPresented, content: {
                UpdateControllerCheckingForUpdatesView(updater: updater)
            })
            .sheet(isPresented: $sheetUpdateNotFoundViewPresented, content: {
                UpdateControllerUpdateNotFoundView(updater: updater)
            })
            .sheet(isPresented: $sheetChangeLogViewPresented, content: {
                 UpdatePreviewView(
                    dismiss: {
                        updater.shouldUpdate(.dismiss)
                    },
                    install: {
                        updater.shouldUpdate(.install)
                    },
                    markdownText: updater.appcastItem?.itemDescription,
                    nextVersion: updater.appcastItem?.displayVersionString ?? "1.0.0",
                    nextVersionNumber: updater.appcastItem?.versionString ?? "0"
                 )
                    .interactiveDismissDisabled()
            })
            .sheet(isPresented: $sheetUpdateInstallingViewPresented, content: {
                UpdateInstallingView(
                    downloadStatedAt: updater.downloadStartedAt,
                    cancelDownload: {
                        updater.cancelDownload()
                    },
                    state: $updater.state,
                    downloadableBytes: $updater.downloadBytesTotal,
                    downloadedBytes: $updater.downloadBytesReceived,
                    extractProgress: $updater.extractProgress
                )
                    .interactiveDismissDisabled()
                    .frame(width: 500)
            })
            .sheet(isPresented: $sheetUpdateReadyToRelaunchViewPresented, content: {
                UpdateControllerReadyToRelaunchView(updater: updater)
            })
            .sheet(isPresented: $sheetUpdateErrorViewPresented, content: {
                UpdateControllerErrorView(updater: updater)
            })
            .onChange(of: updater.state, { _, newValue in
                updateViews(newState: newValue)
            })
    }

    func updateViews(newState: SparkleUpdaterEvents.UpdaterState) {
        // Dissmiss all old views
        sheetCheckingUpdateViewPresented = false
        sheetChangeLogViewPresented = false
        sheetUpdateInstallingViewPresented = false
        sheetUpdateReadyToRelaunchViewPresented = false
        sheetUpdateErrorViewPresented = false
        sheetUpdateNotFoundViewPresented = false

        // Enable new view
        switch newState {
        case .checking:
            sheetCheckingUpdateViewPresented = true
        case .updateFound:
            sheetChangeLogViewPresented = true
        case .initializing, .downloading, .extracting, .installing:
            sheetUpdateInstallingViewPresented = true
        case .readyToRelaunch:
            sheetUpdateReadyToRelaunchViewPresented = true
        case .error:
            sheetUpdateErrorViewPresented = true
        case .updateNotFound:
            sheetUpdateNotFoundViewPresented = true
        case .idle:
            break
        }
    }
}

struct UpdateControllerCheckingForUpdatesView: View {
    let updater: SparkleUpdaterEvents

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BundleIcon().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 12) {
                Text("update.checkingForUpdates")
                    .fontWeight(.bold)
                Text("update.checkingForUpdates.description")
                ProgressView()
                    .progressViewStyle(.linear)
                HStack {
                    Spacer()
                    Button("button.cancel") {
                        updater.cancelUpdateCheck()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 500, alignment: .leading)
        .interactiveDismissDisabled()
    }
}

struct UpdateControllerUpdateNotFoundView: View {
    let updater: SparkleUpdaterEvents

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BundleIcon().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 12) {
                Text("update.noUpdatesFound")
                    .fontWeight(.bold)
                Text("update.noUpdatesFound.description")
                HStack {
                    Spacer()
                    Button("button.ok") {
                        updater.updateNotFoundAcknowledgement()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 500, alignment: .leading)
    }
}

struct UpdateControllerReadyToRelaunchView: View {
    let updater: SparkleUpdaterEvents

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BundleIcon().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 12) {
                Text("update.readyToRelaunch")
                    .fontWeight(.bold)
                Text("update.readyToRelaunch.description")
                HStack {
                    Spacer()
                    Button("update.relaunch") {
                        updater.relaunch(.install)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 500, alignment: .leading)
    }
}

struct UpdateControllerErrorView: View {
    let updater: SparkleUpdaterEvents

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BundleIcon().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 12) {
                Text("update.updaterError")
                    .fontWeight(.bold)
                Text(updater.errorData?.localizedDescription ?? "")
                HStack {
                    Spacer()
                    Button("button.ok") {
                        updater.errorAcknowledgement()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(20)
        .frame(width: 500, alignment: .leading)
    }
}
