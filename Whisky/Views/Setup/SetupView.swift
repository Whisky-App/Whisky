//
//  SetupView.swift
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

enum SetupStage {
    case rosetta
    case whiskyWineDownload
    case whiskyWineInstall
}

struct SetupView: View {
    @State private var path: [SetupStage] = []
    @State var tarLocation: URL = URL(fileURLWithPath: "")
    @Binding var showSetup: Bool
    var firstTime: Bool = true

    var body: some View {
        VStack {
            NavigationStack(path: $path) {
                WelcomeView(path: $path, showSetup: $showSetup, firstTime: firstTime)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: SetupStage.self) { stage in
                        switch stage {
                        case .rosetta:
                            RosettaView(path: $path, showSetup: $showSetup)
                        case .whiskyWineDownload:
                            WhiskyWineDownloadView(tarLocation: $tarLocation, path: $path)
                        case .whiskyWineInstall:
                            WhiskyWineInstallView(tarLocation: $tarLocation, path: $path, showSetup: $showSetup)
                        }
                    }
            }
        }
        .padding()
        .interactiveDismissDisabled()
    }
}
