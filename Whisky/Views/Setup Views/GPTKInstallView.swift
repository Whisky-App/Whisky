//
//  GPTKInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI
import WhiskyKit

struct GPTKInstallView: View {
    @State var installing: Bool = true
    @Binding var tarLocation: URL
    @Binding var path: [SetupStage]
    @Binding var showSetup: Bool

    var body: some View {
        VStack {
            VStack {
                Text("setup.gptk.install")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.gptk.install.subtitle")
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
            Task.detached {
                GPTKInstaller.install(from: tarLocation)
                await MainActor.run {
                    installing = false
                }
                sleep(2)
                await proceed()
            }
        }
    }

    @MainActor
    func proceed() {
        showSetup = false
    }
}
