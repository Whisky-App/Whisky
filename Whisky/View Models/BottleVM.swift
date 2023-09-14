//
//  BottleVM.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import Foundation
import SemanticVersion
import WhiskyKit

class BottleVM: ObservableObject {
    static let shared = BottleVM()

    var bottlesList = BottleData()
    @Published var bottles: [Bottle] = []

    @MainActor
    func loadBottles() {
        bottles.removeAll()

        for (index, path) in bottlesList.paths.enumerated().reversed() where loadBottle(bottleURL: path) == nil {
            bottlesList.paths.remove(at: index)
        }

        bottles = bottlesList.paths.map({
            Bottle(bottleUrl: $0)
        })
        bottles.sortByName()
    }

    func loadBottle(bottleURL: URL) -> BottleSettings? {
        let bottleMetadata = bottleURL
            .appending(path: "Metadata")
            .appendingPathExtension("plist")
            .path(percentEncoded: false)

        if FileManager.default.fileExists(atPath: bottleMetadata) {
            return BottleSettings(bottleURL: bottleURL)
        }

        return .none
    }

    func createNewBottle(bottleName: String, winVersion: WinVersion, bottleURL: URL) -> URL {
        let newBottleDir = bottleURL.appending(path: UUID().uuidString)

        Task.detached { @MainActor in
            var bottleId: Bottle? = .none
            do {
                try FileManager.default.createDirectory(atPath: newBottleDir.path(percentEncoded: false),
                                                        withIntermediateDirectories: true)
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
