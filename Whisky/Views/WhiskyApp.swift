//
//  WhiskyApp.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        Task(priority: .userInitiated) {
            for bottle in BottleVM.shared.bottles {
                do {
                    try await Wine.killBottle(bottle: bottle)
                } catch {
                    print("Failed to kill bottle: \(error)")
                }
            }
        }
    }
}

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
                    Task(priority: .userInitiated) {
                        await AppDB.makeRequest()
                    }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
            }
        }
    }
}
