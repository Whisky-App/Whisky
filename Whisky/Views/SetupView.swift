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
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            NavigationStack(path: $model.path) {
                WelcomeView()
                    .environmentObject(model)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: SetupStage.self) { stage in
                        switch stage {
                        case .rosetta:
                            RosettaView()
                                .environmentObject(model)
                        case .wineDownload:
                            WineDownloadView()
                                .environmentObject(model)
                        case .wineInstall:
                            WineInstallView()
                                .environmentObject(model)
                        case .gptk:
                            GPTKInstallView()
                                .environmentObject(model)
                        }
                    }
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}
