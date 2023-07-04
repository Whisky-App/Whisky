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
    @ObservedObject var model = AppModel()

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BottleVM.shared)
                .environmentObject(model)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    BottleVM.shared.loadBottles()
                    model.bottlesLoaded = true
                    if WineInstaller.shouldUpdateWine() {
                        WineInstaller.uninstallWine()
                        model.showSetup = true
                    }
                    if ProcessInfo().operatingSystemVersion.majorVersion < 14 {
                        Task {
                            let alert = NSAlert()
                            alert.messageText = String(localized: "alert.macos")
                            alert.informativeText = String(localized: "alert.macos.info")
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: String(localized: "button.ok"))
                            alert.runModal()
                        }
                    }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                SparkleView(updater: updaterController.updater)
                Button("open.setup") {
                    model.showSetup = true
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
