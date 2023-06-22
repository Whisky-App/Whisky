//
//  BottleVM.swift
//  Whisky
//
//  Created by Isaac Marovitz on 24/03/2023.
//

import Foundation

struct InflightBottle: Hashable {
    var name: String
    var url: URL
}

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
    @Published var inFlightBottles: [InflightBottle] = []

    enum NameFailureReason {
        case emptyName
        case alreadyExists

        var description: String {
            switch self {
            case .emptyName:
                return String(localized: "create.warning.emptyName")
            case .alreadyExists:
                return String(localized: "create.warning.alreadyExistsName")
            }
        }
    }
    enum BottleValidationResult {
        case success
        case failure(reason: NameFailureReason)
    }

    @MainActor
    func loadBottles() {
        Task(priority: .background) {
            inFlightBottles.removeAll()
            bottles.removeAll()
            // Update if needed
            if !BottleVMEntries.exists() {
                do {
                    let files = try FileManager.default.contentsOfDirectory(
                        at: BottleVM.bottleDir,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    )
                    for file in files where file.pathExtension == "plist" {
                        if let bottlePath = convertFormat(plistPath: file) {
                            bottlesList.paths.append(bottlePath)
                        }
                    }
                } catch {
                    print("Failed to list files")
                }
                bottlesList.encode()
            }

            bottles = bottlesList.paths.map({
                Bottle(bottleUrl: $0)
            })
            bottles.sort(by: { $0.settings.name.lowercased() < $1.settings.name.lowercased() })
        }
    }

    func createNewBottle(bottleName: String, winVersion: WinVersion, bottleURL: URL) {
        let newBottleDir = bottleURL.appendingPathComponent(UUID().uuidString)
        let flight: InflightBottle = .init(name: bottleName, url: newBottleDir)
        inFlightBottles.append(flight)
        Task(priority: .userInitiated) {
            do {
                if !FileManager.default.fileExists(atPath: BottleVM.bottleDir.path) {
                    try FileManager.default.createDirectory(atPath: BottleVM.bottleDir.path,
                                                            withIntermediateDirectories: true)
                }
                try FileManager.default.createDirectory(atPath: newBottleDir.path, withIntermediateDirectories: true)
                let bottle = Bottle(bottleUrl: newBottleDir)
                bottle.settings.windowsVersion = winVersion
                bottle.settings.name = bottleName
                try await Wine.changeWinVersion(bottle: bottle, win: winVersion)
                let wineVer = try await Wine.wineVersion()
                bottle.settings.wineVersion = try Semver.parse(data: wineVer == "" ? "0.0.0" : wineVer)
                // Add record
                self.bottlesList.paths.append(newBottleDir)
                await loadBottles()
            } catch {
                print("Failed to create new bottle: \(error)")
                if let index = inFlightBottles.firstIndex(of: flight) {
                    inFlightBottles.remove(at: index)
                }
            }
        }
    }
}
