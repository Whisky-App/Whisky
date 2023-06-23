//
//  WineDownloadView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineDownloadView: View {
    @State private var fractionProgress: Double = 0
    @State private var completedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var downloadTask: URLSessionDownloadTask?
    @State private var observation: NSKeyValueObservation?
    @State private var startTime: Date?
    @State private var downloadSpeed: Double?
    
    @Binding var tarLocation: URL
    @Binding var path: [SetupStage]
    
    var body: some View {
        VStack {
            VStack {
                Text("setup.wine.download")
                    .font(.title)
                Text("setup.wine.download.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack {
                    ProgressView(value: fractionProgress, total: 1)
                    HStack {
                        HStack {
                                Text(formatBytes(completed: completedBytes, total: totalBytes))
                                Spacer()
                                Text(estimateRemainingTime())
                            }
                            .font(.subheadline)
                            Spacer()
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
                if let downloadInfo = await WineDownload.getLatestWineURL(),
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
    
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: value as NSNumber) ?? ""
    }
    
    func formatBytes(completed: Int64, total: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let completed = formatter.string(fromByteCount: completed)
        let total = formatter.string(fromByteCount: total)
        return "(\(completed)/\(total))"
    }
    
    func estimateRemainingTime() -> String {
        guard let speed = downloadSpeed else {
            return "Estimating..."
        }
        
        let remainingBytes = totalBytes - completedBytes
        let remainingTimeInSeconds = Double(remainingBytes) / speed
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remainingTimeInSeconds) ?? ""
    }
    
    func proceed() {
        path.append(.wineInstall)
    }
}
