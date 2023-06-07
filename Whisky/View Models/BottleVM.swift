//
//  BottleVM.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import Foundation

class BottleVM: ObservableObject {
    static let shared = BottleVM()

    static let containerDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("com.isaacmarovitz.Whisky")

    static let bottleDir = containerDir
        .appendingPathComponent("Bottles")

    @Published var bottles: [Bottle] = []

    @MainActor
    func loadBottles() {
        Task(priority: .background) {
            bottles.removeAll()

            let enumerator = FileManager.default.enumerator(at: BottleVM.bottleDir,
                                                            includingPropertiesForKeys: [.isDirectoryKey],
                                                            options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])

            while let url = enumerator?.nextObject() as? URL {
                let bottle = Bottle(path: url)
                bottles.append(bottle)
            }

            bottles.sort(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
    }

    func createNewBottle(bottleName: String, winVersion: WinVersion) {
        Task(priority: .userInitiated) {
            do {
                if !FileManager.default.fileExists(atPath: BottleVM.bottleDir.path) {
                    try FileManager.default.createDirectory(atPath: BottleVM.bottleDir.path,
                                                            withIntermediateDirectories: true)
                }

                let newBottleDir = BottleVM.bottleDir.appendingPathComponent(bottleName)
                try FileManager.default.createDirectory(atPath: newBottleDir.path, withIntermediateDirectories: true)

                let bottle = Bottle(path: newBottleDir)
                bottle.settings.windowsVersion = winVersion
                try await Wine.changeWinVersion(bottle: bottle, win: winVersion)
                bottle.settings.wineVersion = try await Wine.wineVersion()
                
                await loadBottles()
            } catch {
                print("Failed to create new bottle")
            }
        }
    }
}
