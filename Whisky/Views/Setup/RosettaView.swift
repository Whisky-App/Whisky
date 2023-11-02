//
//  RosettaView.swift
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
