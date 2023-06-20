//
//  WineDownload.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import Foundation

class WineDownload {
    static func getLatestWineURL() async -> DownloadInfo? {
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

struct DownloadInfo {
    let directURL: URL?
    let totalByteCount: Int
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
