//
//  GPTKInstaller.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
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

    public static func shouldUpdateGPTK() async -> (Bool, SemanticVersion) {
        if let localVersion = gptkVersion() {
            let versionPlistURL = "https://data.getwhisky.app/GPTKVersion.plist"

            if let remoteUrl = URL(string: versionPlistURL) {
                return await withCheckedContinuation { continuation in
                    URLSession.shared.dataTask(with: URLRequest(url: remoteUrl)) { data, _, error in
                        do {
                            if error == nil, let data = data {
                                let decoder = PropertyListDecoder()
                                let remoteInfo = try decoder.decode(GPTKVersion.self, from: data)
                                let remoteVersion = remoteInfo.version

                                let isRemoteNewer = remoteVersion > localVersion
                                continuation.resume(returning: (isRemoteNewer, remoteVersion))
                                return
                            }
                            if let error = error {
                                print(error)
                            }
                        } catch {
                            print(error)
                        }
                        continuation.resume(returning: (false, SemanticVersion(0, 0, 0)))
                    }.resume()
                }
            }
        }

        return (false, SemanticVersion(0, 0, 0))
    }

    public static func gptkVersion() -> SemanticVersion? {
        do {
            let versionPlist = libraryFolder
                .appending(path: "GPTKVersion")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(GPTKVersion.self, from: data)
            return info.version
        } catch {
            print(error)
            return nil
        }
    }
}

struct GPTKVersion: Codable {
    var version: SemanticVersion = SemanticVersion(1, 0, 0)
}
