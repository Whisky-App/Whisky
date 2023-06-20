//
//  WineDownloadView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineDownloadView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Downloading Wine")
                    .font(.title)
                Text("Speeds will vary on your internet connection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack {
                    ProgressView(value: 200, total: 435)
                    HStack {
                        Text("Progress: 46% (200/435 MB)")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            Spacer()
        }
    }
}
