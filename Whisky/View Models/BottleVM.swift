//
//  BottleVM.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import Foundation
import SemanticVersion

class BottleVM: ObservableObject {
    static let shared = BottleVM()

    static let containerDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")

    static let bottleDir = containerDir
        .appendingPathComponent("Bottles")
    let bottlesList = BottleVMEntries()

    @Published var bottles: [Bottle] = []

    @MainActor
    func loadBottles() {
        bottles.removeAll()

        for (index, path) in bottlesList.paths.enumerated().reversed() where loadBottle(bottleURL: path) == nil {
            bottlesList.paths.remove(at: index)
        }

        // Update if needed
        if !BottleVMEntries.exists() {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: BottleVM.bottleDir,
                                                                    includingPropertiesForKeys: nil,
                                                                    options: .skipsHiddenFiles)
                for file in files where loadBottle(bottleURL: file) != nil {
                    bottlesList.paths.append(file)
                }
            } catch {
                print("Failed to list files")
            }
            bottlesList.encode()
        }
        bottles = bottlesList.paths.map({
            Bottle(bottleUrl: $0)
        })
        bottles.sortByName()
    }

    func loadBottle(bottleURL: URL) -> BottleSettings? {
        // Try loading as legacy bottle
        do {
            let files = try FileManager.default.contentsOfDirectory(at: bottleURL, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "plist" {
                if let bottlePath = convertFormat(plistPath: file) {
                    return BottleSettings(bottleURL: bottlePath)
                } else {
                    print("Failed to load as legacy bottle")
                }
            }
        } catch {
            print("Failed to load as legacy bottle")
        }

        // Try loading as a normal bottle
        let bottleMetadata = bottleURL
            .appendingPathComponent("Metadata")
            .appendingPathExtension("plist")
            .path()

        if FileManager.default.fileExists(atPath: bottleMetadata) {
            let bottle = BottleSettings(bottleURL: bottleURL)
            bottle.encode()
            return bottle
        }

        return .none
    }

    func createNewBottle(bottleName: String, winVersion: WinVersion, bottleURL: URL) -> URL {
        let newBottleDir = bottleURL.appendingPathComponent(UUID().uuidString)

        Task.detached { @MainActor in
            var bottleId: Bottle? = .none
            do {
                if !FileManager.default.fileExists(atPath: BottleVM.bottleDir.path) {
                    try FileManager.default.createDirectory(atPath: BottleVM.bottleDir.path,
                                                            withIntermediateDirectories: true)
                }

                try FileManager.default.createDirectory(atPath: newBottleDir.path, withIntermediateDirectories: true)
                let bottle = Bottle(bottleUrl: newBottleDir, inFlight: true)
                bottleId = .some(bottle)

                self.bottles.append(bottle)
                self.bottles.sortByName()

                bottle.settings.windowsVersion = winVersion
                bottle.settings.name = bottleName
                try await Wine.changeWinVersion(bottle: bottle, win: winVersion)
                let wineVer = try await Wine.wineVersion()
                bottle.settings.wineVersion = SemanticVersion(wineVer) ?? SemanticVersion(0, 0, 0)
                // Add record
                self.bottlesList.paths.append(newBottleDir)
                self.loadBottles()
            } catch {
                print("Failed to create new bottle: \(error)")
                if let bottle = bottleId {
                    if let index = self.bottles.firstIndex(of: bottle) {
                        self.bottles.remove(at: index)
                    }
                }
            }
        }
        return newBottleDir
    }
}
