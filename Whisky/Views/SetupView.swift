//
//  SetupView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import SwiftUI

enum SetupStage {
    case welcome
    case rosetta
    case wineDownload
    case wineInstall
    case gptk
    case finished
}

struct SetupView: View {
    @State var canContinue: Bool = false
    @State private var path: [SetupStage] = []
    @State var tarLocation: URL = URL(fileURLWithPath: "")

    var body: some View {
        VStack {
            NavigationStack(path: $path) {
                WelcomeView(canContinue: $canContinue)
                    .navigationDestination(for: SetupStage.self) { stage in
                        switch stage {
                        case .welcome:
                            WelcomeView(canContinue: $canContinue)
                        case .rosetta:
                            RosettaView()
                        case .wineDownload:
                            WineDownloadView(tarLocation: $tarLocation)
                        case .wineInstall:
                            WineInstallView(tarLocation: $tarLocation)
                        case .gptk:
                            GPTKInstallView()
                        case .finished:
                            Text("all done")
                        }
                    }
            }
            Spacer()
            HStack {
                Button("Quit") {
                    exit(0)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Next") {
                    switch path.last {
                    case .welcome, .none:
                        if Arch.getArch() == .arm {
                            if !Rosetta2.isRosettaInstalled {
                                path.append(.rosetta)
                                break
                            }
                        }

                        fallthrough
                    case .rosetta:
                        if !WineInstaller.isWineInstalled() {
                            path.append(.wineDownload)
                            break
                        }

                        if !GPTK.isGPTKInstalled() {
                            path.append(.gptk)
                            break
                        }

                        path.append(.finished)
                    case .wineDownload:
                        path.append(.wineInstall)
                    case .wineInstall:
                        if !GPTK.isGPTKInstalled() {
                            path.append(.gptk)
                            break
                        }

                        path.append(.finished)
                    case .gptk:
                        path.append(.finished)
                    case .finished:
                        break
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
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
