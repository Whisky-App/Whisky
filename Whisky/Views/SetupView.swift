//
//  SetupView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import SwiftUI

enum SetupStage {
    case rosetta
    case wineDownload
    case wineInstall
    case gptk
}

struct SetupView: View {
    @State private var path: [SetupStage] = []
    @State var tarLocation: URL = URL(fileURLWithPath: "")
    @Binding var showSetup: Bool

    var body: some View {
        VStack {
            NavigationStack(path: $path) {
                WelcomeView(path: $path, showSetup: $showSetup)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: SetupStage.self) { stage in
                        switch stage {
                        case .rosetta:
                            RosettaView(path: $path, showSetup: $showSetup)
                        case .wineDownload:
                            WineDownloadView(tarLocation: $tarLocation, path: $path)
                        case .wineInstall:
                            WineInstallView(tarLocation: $tarLocation, path: $path, showSetup: $showSetup)
                        case .gptk:
                            GPTKInstallView(path: $path, showSetup: $showSetup)
                        }
                    }
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}
