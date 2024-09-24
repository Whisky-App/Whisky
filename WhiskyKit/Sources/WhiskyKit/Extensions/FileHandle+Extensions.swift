//
//  FileHandle+Extensions.swift
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
import os.log
import SemanticVersion

extension FileHandle {
    func extract<T>(_ type: T.Type, offset: UInt64 = 0) -> T? {
        do {
            try self.seek(toOffset: offset)
            if let data = try self.read(upToCount: MemoryLayout<T>.size) {
                return data.withUnsafeBytes { $0.loadUnaligned(as: T.self)}
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    func write(line: String) {
        do {
            guard let data = line.data(using: .utf8) else { return }
            try write(contentsOf: data)
        } catch {
            Logger.wineKit.info("Failed to write line: \(error)")
        }
    }

    // swiftlint:disable line_length
    func writeApplicaitonInfo() {
        var header = String()
        let macOSVersion = ProcessInfo.processInfo.operatingSystemVersion

        header += "Whisky Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "")\n"
        header += "Date: \(ISO8601DateFormatter().string(from: Date.now))\n"
        header += "macOS Version: \(macOSVersion.majorVersion).\(macOSVersion.minorVersion).\(macOSVersion.patchVersion)\n\n"
        write(line: header)
    }
    // swiftlint:enable line_length

    func writeInfo(for process: Process) {
        var header = String()

        if let arguments = process.arguments {
            header += "Arguments: \(arguments.joined(separator: " "))\n\n"
        }

        if let environment = process.environment, !environment.isEmpty {
            header += "Environment:\n\(environment as AnyObject)\n\n"
        }

        write(line: header)
    }

    func writeInfo(for bottle: Bottle) {
        var header = String()
        header += "Bottle Name: \(bottle.settings.name)\n"
        header += "Bottle URL: \(bottle.url.path)\n\n"

        if let version = WhiskyWineInstaller.whiskyWineVersion() {
            header += "WhiskyWine Version: \(version.major).\(version.minor).\(version.patch)\n"
        }
        header += "Windows Version: \(bottle.settings.windowsVersion)\n"
        header += "Enhanced Sync: \(bottle.settings.enhancedSync)\n\n"

        header += "Metal HUD: \(bottle.settings.metalHud)\n"
        header += "Metal Trace: \(bottle.settings.metalTrace)\n\n"

        if bottle.settings.dxvk {
            header += "DXVK: \(bottle.settings.dxvk)\n"
            header += "DXVK Async: \(bottle.settings.dxvkAsync)\n"
            header += "DXVK HUD: \(bottle.settings.dxvkHud)\n\n"
        }

        write(line: header)
    }
}
