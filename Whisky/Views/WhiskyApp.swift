//
//  WhiskyApp.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import Sparkle

@main
struct WhiskyApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BottleVM.shared)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
            }
        }
    }
}
