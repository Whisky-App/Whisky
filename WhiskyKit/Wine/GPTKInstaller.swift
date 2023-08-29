//
//  GPTKInstaller.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/06/2023.
//

import Foundation
import SemanticVersion

public class GPTKInstaller {
    public static let libraryFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask)[0]
        .appending(path: Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")
        .appending(path: "Libraries")

    public static func isGPTKInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: libraryFolder.path)
    }

    public static func install(from: URL) {
        do {
            let whiskySupportFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask)[0]
                .appending(path: Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")

            if !FileManager.default.fileExists(atPath: whiskySupportFolder.path) {
                try FileManager.default.createDirectory(at: whiskySupportFolder, withIntermediateDirectories: true)
            } else {
                // Recreate it
                try FileManager.default.removeItem(at: whiskySupportFolder)
                try FileManager.default.createDirectory(at: whiskySupportFolder, withIntermediateDirectories: true)
            }

            try Tar.untar(tarBall: from, toURL: whiskySupportFolder)

            let tarFile = whiskySupportFolder
                .appending(path: "Libraries")
                .appendingPathExtension("tar")
                .appendingPathExtension("gz")
            try Tar.untar(tarBall: tarFile, toURL: whiskySupportFolder)
            try FileManager.default.removeItem(at: tarFile)
        } catch {
            print("Failed to install GPTK: \(error)")
        }
    }

    public static func uninstall() {
        let libraryFolder = FileManager.default.urls(for: .applicationSupportDirectory,
                                                           in: .userDomainMask)[0]
            .appending(path: Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")
            .appending(path: "Libraries")

        do {
            try FileManager.default.removeItem(at: libraryFolder)
        } catch {
            print("Failed to uninstall GPTK: \(error)")
        }
    }

    public static func shouldUpdateGPTK() async -> Bool {
        let decoder = PropertyListDecoder()
        let versionPlist = libraryFolder
            .appending(path: "GPTKVersion")
            .appendingPathExtension("plist")

        do {
            let localData = try Data(contentsOf: versionPlist)
            let localInfo = try decoder.decode(GPTKVersion.self, from: localData)
            let localVersion = localInfo.version
            let githubURL = "https://raw.githubusercontent.com/Whisky-App/WhiskyBuilder/main/GPTKVersion.plist"

            if let remoteUrl = URL(string: githubURL) {
                return await withCheckedContinuation { continuation in
                    URLSession.shared.dataTask(with: URLRequest(url: remoteUrl)) { data, _, error in
                        do {
                            if error == nil, let data = data {
                                let remoteInfo = try decoder.decode(GPTKVersion.self, from: data)
                                let remoteVersion = remoteInfo.version

                                let isRemoteNewer = remoteVersion > localVersion
                                continuation.resume(returning: isRemoteNewer)
                                return
                            }
                            if let error = error {
                                print(error)
                            }
                        } catch {
                            print(error)
                        }
                        continuation.resume(returning: false)
                    }.resume()
                }
            }
        } catch {
            print(error)
        }

        return false
    }

    public static func gptkVersion() -> String? {
        do {
            let versionPlist = libraryFolder
                .appending(path: "Wine")
                .appending(path: "external")
                .appending(path: "D3DMetal.framework")
                .appending(path: "Versions")
                .appending(path: "A")
                .appending(path: "Resources")
                .appending(path: "version")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(VersionInfo.self, from: data)
            return info.CFBundleShortVersionString
        } catch {
            print(error)
            return nil
        }
    }
}

struct VersionInfo: Codable {
    let CFBundleShortVersionString: String
}

struct GPTKVersion: Codable {
    var version: SemanticVersion = SemanticVersion(1, 0, 0)
}
