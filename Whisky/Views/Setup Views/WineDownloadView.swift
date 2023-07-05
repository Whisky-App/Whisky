//
//  WineDownloadView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineDownloadView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        VStack {
            VStack {
                Text("setup.wine.download")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.wine.download.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack {
                    if shouldShowEstimate() {
                        ProgressView(value: model.fractionProgress, total: 1)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
                    HStack {
                        HStack {
                            Text(String(format: String(localized: "setup.wine.progress"),
                                        formatBytes(bytes: model.completedBytes),
                                        formatBytes(bytes: model.totalBytes)))
                            + Text(" ")
                            + (shouldShowEstimate() ?
                               Text(String(format: String(localized: "setup.wine.eta"),
                                           formatRemainingTime(remainingBytes:
                                                                model.totalBytes - model.completedBytes)))
                               : Text(""))
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
    }

    func formatBytes(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }

    func shouldShowEstimate() -> Bool {
        return model.fractionProgress > 0.01 && model.completedBytes != 0
    }

    func formatRemainingTime(remainingBytes: Int64) -> String {
        let remainingTimeInSeconds = Double(remainingBytes) / model.downloadSpeed

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
