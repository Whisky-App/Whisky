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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
            }
            CommandGroup(after: .importExport) {
                Button {
                    WhiskyApp.killBottles()
                } label: {
                    Text("kill.bottles")
                }
            }
        }
    }

    static func killBottles() {
        for bottle in BottleVM.shared.bottles {
            do {
                try Wine.killBottle(bottle: bottle)
            } catch {
                print("Failed to kill bottle: \(error)")
            }
        }
    }
}
