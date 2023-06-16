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
            CommandGroup(after: .newItem) {
                Button("Import Bottle") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = false
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                let bottle = BottleSettingsData(url: url)
                                let encoder = PropertyListEncoder()
                                encoder.outputFormat = .xml

                                do {
                                    let data = try encoder.encode(bottle)
                                    let name = url.lastPathComponent
                                    if case .success = BottleVM.shared.isValidBottleName(bottleName: name) {
                                        try data.write(to: BottleVM.bottleDir
                                            .appendingPathComponent(name)
                                            .appendingPathExtension("plist"))
                                        BottleVM.shared.loadBottles()
                                    } else {
                                        print("Invalid bottle name!")
                                    }
                                } catch {
                                    print("Failed to import bottle!")
                                }
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
