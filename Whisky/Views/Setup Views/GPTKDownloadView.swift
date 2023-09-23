//
//  GPTKDownloadView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI
import WhiskyKit

struct GPTKDownloadView: View {
    @State private var fractionProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var downloadSpeed: Double = 0
    @State private var downloadTask: URLSessionDownloadTask?
    @State private var observation: NSKeyValueObservation?
    @State private var startTime: Date?
    @Binding var tarLocation: URL
    @Binding var path: [SetupStage]
    var body: some View {
        VStack {
            VStack {
                Text("setup.gptk.download")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.gptk.download.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack {
                    ProgressView(value: fractionProgress, total: 1)
                    HStack {
                        HStack {
                            Text(String(format: String(localized: "setup.gptk.progress"),
                                        formatBytes(bytes: completedBytes),
                                        formatBytes(bytes: totalBytes)))
                            + Text(" ")
                            + (shouldShowEstimate() ?
                               Text(String(format: String(localized: "setup.gptk.eta"),
                                           formatRemainingTime(remainingBytes: totalBytes - completedBytes)))
                               : Text(String()))
                            Spacer()
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
        .onAppear {
            Task {
                if let downloadInfo = await GPTKDownloader.getLatestGPTKURL(),
                   let url = downloadInfo.directURL {
                    downloadTask = URLSession.shared.downloadTask(with: url) { url, _, _ in
                        if let url = url {
                            tarLocation = url
                            proceed()
                        }
                    }
                    observation = downloadTask?.observe(\.countOfBytesReceived) { task, _ in
                        Task {
                            await MainActor.run {
                                let currentTime = Date()
                                let elapsedTime = currentTime.timeIntervalSince(startTime ?? currentTime)
                                if completedBytes > 0 {
                                    downloadSpeed = Double(completedBytes) / elapsedTime
                                }
                                fractionProgress = Double(task.countOfBytesReceived) / Double(totalBytes)
                                completedBytes = task.countOfBytesReceived
                            }
                        }
                    }
                    startTime = Date()
                    downloadTask?.resume()
                    await MainActor.run {
                        totalBytes = Int64(downloadInfo.totalByteCount)
                    }
                }
            }
        }
    }

    func formatBytes(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }

    func shouldShowEstimate() -> Bool {
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        return Int(elapsedTime.rounded()) > 5 && completedBytes != 0
    }

    func formatRemainingTime(remainingBytes: Int64) -> String {
        let remainingTimeInSeconds = Double(remainingBytes) / downloadSpeed

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        if shouldShowEstimate() {
            return formatter.string(from: TimeInterval(remainingTimeInSeconds)) ?? ""
        } else {
            return ""
        }
    }

    func proceed() {
        path.append(.gptkInstall)
    }
}
