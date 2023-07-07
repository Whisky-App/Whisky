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
    @State var showSetup: Bool = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(showSetup: $showSetup)
                .environmentObject(BottleVM.shared)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
                Divider()
                Button("open.setup") {
                    showSetup = true
                }
            }
            CommandGroup(after: .newItem) {
                Button("open.bottle") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                let bottleMetadata = url
                                    .appendingPathComponent("Metadata")
                                    .appendingPathExtension("plist")
                                    .path()

                                if FileManager.default.fileExists(atPath: bottleMetadata) {
                                    // Legacy files
                                    let bottle = BottleSettings(bottleURL: url)
                                    bottle.encode()
                                }

                                BottleVM.shared.bottlesList.paths.append(url)
                                BottleVM.shared.loadBottles()
                            }
                        }
                    }
                }
                .keyboardShortcut("I", modifiers: [.command])
            }
            CommandGroup(after: .importExport) {
                Button("open.logs") {
                    WhiskyApp.openLogsFolder()
                }
                .keyboardShortcut("L", modifiers: [.command])
                Button("kill.bottles") {
                    WhiskyApp.killBottles()
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])
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

    static func openLogsFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Log.logsFolder.path)
    }
}
