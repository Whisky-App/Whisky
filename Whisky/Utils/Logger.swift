//
//  Logger.swift
//  Whisky
//
//  Created by Isaac Marovitz on 08/06/2023.
//

import Foundation
import OSLog

class Log {
    static let logsFolder = FileManager.default.urls(for: .libraryDirectory,
                                                    in: .userDomainMask)[0]
        .appendingPathComponent("Logs")
        .appendingPathComponent("Whisky")

    let fileHandle: FileHandle
    let logger: Logger

    init?() {
        do {
            if !FileManager.default.fileExists(atPath: Log.logsFolder.path) {
                try FileManager.default.createDirectory(at: Log.logsFolder, withIntermediateDirectories: true)
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM y HH:mm"

            let dateString = formatter.string(from: Date.now)
            let fileURL = Log.logsFolder
                .appendingPathComponent(dateString)
                .appendingPathExtension("log")

            try "".write(to: fileURL, atomically: true, encoding: .utf8)

            fileHandle = try FileHandle(forWritingTo: fileURL)

            if let bundleID = Bundle.main.bundleIdentifier {
                logger = Logger(subsystem: bundleID, category: "wine")
            } else {
                throw "Could not get Bundle ID!"
            }
        } catch {
            print("Failed to create logger: \(error.localizedDescription)")
            return nil
        }
    }

    func write(line: String) {
        logger.log("\(line, privacy: .public)")

        if let data = line.data(using: .utf8) {
            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                print("Failed to write line to log: \"\(line)\"!")
            }
        }
    }

    deinit {
        do {
            try fileHandle.close()
        } catch {
            print("Failed to close log file handle!")
        }
    }
}
