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
            var runCount = 0
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                runCount += 1

                if Rosetta2.isRosettaInstalled {
                    timer.invalidate()
                    installing = false
                    Task.detached {
                        sleep(2)
                        await proceed()
                    }
                }
                if runCount >= 300 {
                    // Timer has run for too long
                    timer.invalidate()
                    installing = false
                    Task.detached {
                        sleep(2)
                        await proceed()
                    }
                }
            }
        }
    }

    @MainActor
    func proceed() {
        if !GPTKInstaller.isGPTKInstalled() {
            path.append(.gptkDownload)
            return
        }

        showSetup = false
    }
}
