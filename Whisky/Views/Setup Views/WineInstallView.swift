//
//  WineInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineInstallView: View {
    @State var installing: Bool = true
    @Binding var tarLocation: URL
    @Binding var path: [SetupStage]
    @Binding var showSetup: Bool

    var body: some View {
        VStack {
            VStack {
                Text("setup.wine.install")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.wine.install.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if installing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 80)
                } else {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.green)
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
        .onAppear {
            Task {
                WineInstaller.installWine(from: tarLocation)
                installing = false
                proceed()
            }
        }
    }

    func proceed() {
        if !GPTK.isGPTKInstalled() {
            path.append(.gptk)
            return
        }

        showSetup = false
    }
}
