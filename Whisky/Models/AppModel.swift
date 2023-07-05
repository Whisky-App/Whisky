//
//  AppModel.swift
//  Whisky
//
//  Created by 朱拂 on 2023/7/4.
//

import Foundation

class AppModel: ObservableObject {
    @Published var showSetup: Bool = false {
        didSet {
            UserDefaults.standard.set(showSetup, forKey: "showSetup")
        }
    }
    @Published var bottlesLoaded: Bool = false
    @Published var wineInstalling: Bool = false
    @Published var rosettaInstalling: Bool = false
    @Published var gptkInstalling: Bool = false
    @Published var path: [SetupStage] = []

    @Published var fractionProgress: Double = 0
    @Published var completedBytes: Int64 = 0
    @Published var totalBytes: Int64 = 0
    @Published var downloadSpeed: Double = 0
    @Published var gptkLocation: URL? {
        didSet {
            if let url = gptkLocation {
                gptkDropObserver?(url)
            }
        }
    }

    private var tarLocation: URL?
    private var gptkDropObserver: ((_ url: URL) -> Void)?

    func proceedSetup() async {
        while !path.isEmpty {
            switch path.last {
            case .wineDownload:
                if let url = await downloadWine() {
                    self.tarLocation = url
                }
            case .wineInstall:
                if let tar = tarLocation {
                    await installWine(tar: tar)
                }
            case .rosetta:
                await installRosetta()
            case .gptk:
                await installGPKT()
            default:
                break
            }
            _ = await MainActor.run {
                self.path.removeLast()
            }
        }
        _ = await MainActor.run {
            self.showSetup = false
        }
    }

    func downloadWine() async -> URL? {
        if let downloadInfo = await WineDownload.getLatestWineURL(),
           let url = downloadInfo.directURL {
            DispatchQueue.main.async {
                self.totalBytes = Int64(downloadInfo.totalByteCount)
            }

            let startTime = Date()
            var observation: NSKeyValueObservation?
            defer {
                observation?.invalidate()
            }

            return await withUnsafeContinuation { continuation in
                let downloadTask = URLSession.shared.downloadTask(with: url) { url, _, _ in
                    continuation.resume(returning: url)
                }
                observation = downloadTask.observe(\.countOfBytesReceived) { task, _ in
                    DispatchQueue.main.async {
                        let currentTime = Date()
                        let elapsedTime = currentTime.timeIntervalSince(startTime)
                        if self.completedBytes > 0 {
                            self.downloadSpeed = Double(self.completedBytes) / elapsedTime
                        }
                        self.fractionProgress = Double(task.countOfBytesReceived) / Double(self.totalBytes)
                        self.completedBytes = task.countOfBytesReceived
                    }
                }

                downloadTask.resume()
            }
        }

        return nil
    }

    func installWine(tar: URL) async {
        await MainActor.run {
            wineInstalling = true
        }
        await WineInstaller.installWine(from: tar)
        await MainActor.run {
            wineInstalling = false
        }
    }

    func installRosetta() async {
        Rosetta2.launchRosettaInstaller()
        DispatchQueue.main.async {
            self.rosettaInstalling = true
        }
        repeat {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                // ignored
            }
        } while !Rosetta2.isRosettaInstalled

        DispatchQueue.main.async {
            self.rosettaInstalling = false
        }
    }

    func installGPKT() async {
        await withUnsafeContinuation { continuation in
            gptkDropObserver = { url in
                self.gptkInstalling = true
                GPTK.install(url: url)
                self.gptkInstalling = false
                continuation.resume()
            }
        }
    }

    init() {
        self.showSetup = UserDefaults.standard.bool(forKey: "showSetup")
    }
}
