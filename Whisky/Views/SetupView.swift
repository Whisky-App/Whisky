//
//  SetupView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import SwiftUI

enum SetupStage {
    case rosetta
    case gptkDownload
    case gptkInstall
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
                        case .gptkDownload:
                            GPTKDownloadView(tarLocation: $tarLocation, path: $path)
                        case .gptkInstall:
                            GPTKInstallView(tarLocation: $tarLocation, path: $path, showSetup: $showSetup)
                        }
                    }
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}
