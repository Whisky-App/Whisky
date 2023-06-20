//
//  WineInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineInstallView: View {
    @State var installing: Bool = true
    var tarLocation: URL

    var body: some View {
        VStack {
            VStack {
                Text("Installing Wine")
                    .font(.title)
                Text("Almost there. Don't tune out yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if installing {
                        ProgressView()
                            .scaleEffect(2)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .foregroundStyle(.green)
                    }
                }
                .frame(width: 80, height: 80)
                Spacer()
            }
            Spacer()
        }
        .onAppear {
            Task {
                WineInstaller.installWine(from: tarLocation)
                installing = false
            }
        }
    }
}
