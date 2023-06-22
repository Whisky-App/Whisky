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
        .appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")

    static let bottleDir = containerDir
        .appendingPathComponent("Bottles")
    
    let bottlesList = BottleVMEntries()

    @Published var bottles: [Bottle] = []
    @Published var inFlightBottles: [String] = []

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
                    let files = try FileManager.default.contentsOfDirectory(at: BottleVM.bottleDir,                                                  includingPropertiesForKeys: nil,
                                                                            options: .skipsHiddenFiles)
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
            bottles.sort(by: { $0.name.lowercased() < $1.name.lowercased() })
        }
    }

    func createNewBottle(bottleName: String, winVersion: WinVersion, bottleURL: URL) {
        inFlightBottles.append(bottleName)
        Task(priority: .userInitiated) {
            do {
                if !FileManager.default.fileExists(atPath: BottleVM.bottleDir.path) {
                    try FileManager.default.createDirectory(atPath: BottleVM.bottleDir.path,
                                                            withIntermediateDirectories: true)
                }

                let newBottleDir = bottleURL.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(atPath: newBottleDir.path, withIntermediateDirectories: true)

                let bottle = Bottle(bottleUrl: newBottleDir)
                bottle.settings.windowsVersion = winVersion
                try await Wine.changeWinVersion(bottle: bottle, win: winVersion)
                bottle.settings.wineVersion = try Semver.parse(data: try await Wine.wineVersion())
                await loadBottles()
            } catch {
                print("Failed to create new bottle")
            }
        }
    }
}
