//
//  UpdateInstallingView.swift
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

struct UpdateInstallingView: View {
    let downloadStatedAt: Date?
    let cancelDownload: () -> Void

    @Binding var state: SparkleUpdaterEvents.UpdaterState
    @Binding var downloadableBytes: Double
    @Binding var downloadedBytes: Double
    @Binding var extractProgress: Double

    @State private var fractionProgress: Double = 0
    @State private var downloadSpeed: Double = 0
    @State private var shouldShowEstimate: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BundleIcon().frame(width: 60, height: 60)
            VStack(alignment: .leading, spacing: 12) {
                if state == .downloading {
                    Text("update.downloading")
                        .fontWeight(.bold)
                } else if state == .extracting {
                    Text("update.extracting")
                        .fontWeight(.bold)
                } else if state == .installing {
                    Text("update.installing")
                        .fontWeight(.bold)
                } else if state == .initializing {
                    Text("update.initializating")
                        .fontWeight(.bold)
                }
                if state == .installing || state == .initializing {
                    ProgressView()
                        .progressViewStyle(.linear)
                } else if state == .downloading || state == .extracting {
                    VStack(spacing: 2) {
                        ProgressView(value: fractionProgress, total: 1)
                            .progressViewStyle(.linear)
                        if state == .downloading {
                            HStack {
                                Text(String(format: String(localized: "setup.gptk.progress"),
                                            formatBytes(bytes: downloadedBytes),
                                            formatBytes(bytes: downloadableBytes)))
                                + Text(String(" "))
                                + (shouldShowEstimate ?
                                   Text(String(format: String(localized: "setup.gptk.eta"),
                                               formatRemainingTime(
                                                remainingBytes: downloadableBytes - downloadedBytes)))
                                   : Text(String()))
                                Spacer()
                            }
                            .font(.subheadline)
                            .monospacedDigit()
                        }
                    }
                    if state == .downloading {
                        HStack {
                            Spacer()
                            Button("button.cancel") {
                                cancelDownload()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)

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
            if state != .downloading {
                return
            }
            if let downloadStatedAt = downloadStatedAt {
                checkShouldShowEstimate()
                let currentTime = Date()
                let elapsedTime = currentTime.timeIntervalSince(downloadStatedAt)
                if downloadedBytes > 0 {
                    downloadSpeed = Double(downloadedBytes) / elapsedTime
                } else {
                    downloadSpeed = 0
                }
                withAnimation {
                    if downloadableBytes > 0 {
                        fractionProgress = downloadedBytes / downloadableBytes
                    } else {
                        fractionProgress = 0
                    }
                }
            } else {
                downloadSpeed = 0
                fractionProgress = 0
            }

        }
        .onChange(of: extractProgress) {
            if state != .extracting {
                return
            }
            withAnimation {
                fractionProgress = extractProgress / 100
            }
        }
        .onChange(of: state) {
            if state == .installing {
                update()
            }
        }
        .onAppear {
            if state == .installing {
                update()
            }
        }
    }

    func formatBytes(bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    func update() {
        Task(priority: .low) {
            // Stuff
            try await Task.sleep(nanoseconds: UInt64(2 * Double(NSEC_PER_SEC)))
            // Relaunch using sketchy ways
            await WhiskyApp.killBottles()
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
            exit(0)
        }
    }

    func checkShouldShowEstimate() {
        if let downloadStatedAt = downloadStatedAt {
            let elapsedTime = Date().timeIntervalSince(downloadStatedAt)
            withAnimation {
                shouldShowEstimate = Int(elapsedTime.rounded()) > 5 && downloadedBytes != 0
            }
            return
        }

        withAnimation {
            shouldShowEstimate = false
        }
    }

    func formatRemainingTime(remainingBytes: Double) -> String {
        if downloadSpeed == 0 {
            return ""
        }
        let remainingTimeInSeconds = remainingBytes / downloadSpeed

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter.string(from: TimeInterval(remainingTimeInSeconds)) ?? ""
    }
}

#Preview {
    UpdateInstallingView(
        downloadStatedAt: .none,
        cancelDownload: {},
        state: .constant(.downloading),
        downloadableBytes: .constant(1000000),
        downloadedBytes: .constant(1000),
        extractProgress: .constant(0))
    .frame(width: 500)

}
