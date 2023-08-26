//
//  RosettaView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI
import WhiskyKit

struct RosettaView: View {
    @State var installing: Bool = true
    @Binding var path: [SetupStage]
    @Binding var showSetup: Bool

    var body: some View {
        VStack {
            VStack {
                Text("setup.rosetta")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.rosetta.subtitle")
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
        .frame(width: 400, height: 200)
        .onAppear {
            Rosetta2.launchRosettaInstaller()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if Rosetta2.isRosettaInstalled {
                    installing = false
                    proceed()
                    timer.invalidate()
                }
            }
        }
    }

    func proceed() {
        if !WineInstaller.isWineInstalled() {
            path.append(.wineDownload)
            return
        }

        if !GPTK.isGPTKInstalled() {
            path.append(.gptk)
            return
        }

        showSetup = false
    }
}
