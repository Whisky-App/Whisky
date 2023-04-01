//
//  Wine.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

class Wine {
    static let binFolder: URL = (Bundle.main.resourceURL ?? URL(fileURLWithPath: ""))
        .appendingPathComponent("Libraries")
        .appendingPathComponent("Wine")
        .appendingPathComponent("bin")

    static let dxvkFolder: URL = (Bundle.main.resourceURL ?? URL(fileURLWithPath: ""))
        .appendingPathComponent("Libraries")
        .appendingPathComponent("DXVK")

    static let wineBinary: URL = binFolder
        .appendingPathComponent("wine")

    static func run(_ args: [String], bottle: Bottle? = nil) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = wineBinary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        process.currentDirectoryURL = binFolder

        if let bottle = bottle {
            var env: [String: String]
            env = ["WINEPREFIX": bottle.url.path, "WINEDEBUG": "fixme-all"]

            let settings = bottle.settings.settings
            if settings.dxvk {
                env.updateValue("d3d11,dxgi,d3d10core=n,b", forKey: "WINEDLLOVERRIDES")
                if settings.dxvkHud {
                    env.updateValue("devinfo,fps,frametimes", forKey: "DXVK_HUD")
                }
            }

            if settings.esync {
                env.updateValue("1", forKey: "WINEESYNC")
            }

            if settings.metalHud {
                env.updateValue("1", forKey: "MTL_HUD_ENABLED")
            }

            if settings.metalTrace {
                env.updateValue("1", forKey: "METAL_CAPTURE_ENABLED")
                // Might not be needed
                env.updateValue("2", forKey: "MVK_CONFIG_AUTO_GPU_CAPTURE_SCOPE")
            }

            process.environment = env
        }

        try process.run()

        if let output = try pipe.fileHandleForReading.readToEnd() {
            let outputString = String(decoding: output, as: UTF8.self)
            print(outputString)
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                throw outputString
            }

            return outputString
        }

        return ""
    }

    static func wineVersion() async throws -> String {
        var output = try await run(["--version"])
        output.replace("wine-", with: "")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func winVersion(bottle: Bottle) async throws -> WinVersion {
        let output = try await run(["winecfg", "-v"], bottle: bottle)
        let lines = output.split(whereSeparator: \.isNewline)

        if let lastLine = lines.last {
            let winString = String(lastLine)

            if let version = WinVersion(rawValue: winString) {
                return version
            }
        }

        throw WineInterfaceError.invalidResponce
    }

    @discardableResult
    static func cfg(bottle: Bottle) async throws -> String {
        return try await run(["winecfg"], bottle: bottle)
    }

    @discardableResult
    static func changeWinVersion(bottle: Bottle, win: WinVersion) async throws -> String {
        return try await run(["winecfg", "-v", win.rawValue], bottle: bottle)
    }

    @discardableResult
    static func runProgram(bottle: Bottle, path: String) async throws -> String {
        return try await run(["start", "/unix", path], bottle: bottle)
    }
}

extension String: Error {}

enum WineInterfaceError: Error {
    case invalidResponce
}
