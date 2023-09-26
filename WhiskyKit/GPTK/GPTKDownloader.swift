//
//  GPTKDownloader.swift
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

public class GPTKDownloader {
    public static func getLatestGPTKURL() async -> DownloadInfo? {
        let githubURL = "https://api.github.com/repos/IsaacMarovitz/WhiskyBuilder/actions/artifacts"
        if let artifactsURL = URL(string: githubURL) {
            return await withCheckedContinuation { continuation in
                URLSession.shared.dataTask(with: URLRequest(url: artifactsURL)) { data, _, error in
                    do {
                        if error == nil, let data = data {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase
                            let artifacts: Artifacts = try decoder.decode(Artifacts.self, from: data)
                            // We gotta turn the URL into a nightly.link URL
                            if let latest = artifacts.artifacts.first {
                                var url = latest.url
                                url.replace("https://api.github.com/repos/", with: "https://nightly.link/")
                                let selection = "actions/"
                                if let range = url.range(of: selection) {
                                    url = String(url[..<range.upperBound])
                                    url += "runs/\(latest.workflowRun.id)/\(latest.name).zip"
                                    continuation.resume(returning: DownloadInfo(directURL: URL(string: url),
                                                                                totalByteCount: latest.sizeInBytes))
                                    return
                                }
                            }
                        }
                    } catch {
                        print(error)
                    }
                    continuation.resume(returning: nil)
                }.resume()
            }
        }
        return nil
    }
}

public struct DownloadInfo {
    public let directURL: URL?
    public let totalByteCount: Int
}

struct Artifacts: Codable {
    let totalCount: Int
    let artifacts: [Artifact]
}

struct Artifact: Codable {
    let name: String
    let sizeInBytes: Int
    let url: String
    let workflowRun: WorkflowInfo
}

struct WorkflowInfo: Codable {
    let id: Int
}
