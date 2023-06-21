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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            NavigationStack(path: $path) {
                WelcomeView(path: $path)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: SetupStage.self) { stage in
                        switch stage {
                        case .rosetta:
                            RosettaView(path: $path)
                        case .wineDownload:
                            WineDownloadView(tarLocation: $tarLocation, path: $path)
                        case .wineInstall:
                            WineInstallView(tarLocation: $tarLocation, path: $path)
                        case .gptk:
                            GPTKInstallView()
                        }
                    }
            }
        }
        .padding()
        .frame(width: 400, height: 250)
        .interactiveDismissDisabled()
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
