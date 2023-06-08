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

    static let wineBinary: URL = binFolder
        .appendingPathComponent("wine64")

    static let wineserverBinary: URL = binFolder
        .appendingPathComponent("wineserver")

    static func run(_ args: [String],
                    bottle: Bottle? = nil,
                    environment: [String: String]? = nil) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        guard let log = Log() else {
            return ""
        }

        process.executableURL = wineBinary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        process.currentDirectoryURL = binFolder
        pipe.fileHandleForReading.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                log.write(line: "\(line)")
            }
        }

        if let bottle = bottle {
            var env: [String: String]
            env = ["WINEPREFIX": bottle.url.path,
                   "WINEDEBUG": "fixme-all",
                   "WINEBOOT_HIDE_DIALOG": "1"]

            if let environment = environment {
                for variable in environment.keys {
                    env[variable] = environment[variable]
                }
            }

            bottle.settings
                  .environmentVariables(environment: &env)

            process.environment = env
        }

        try process.run()
        print("\nLaunched Wine (\(process.processIdentifier))")

        process.waitUntilExit()
        print("Process exited with code \(process.terminationStatus)")

        if process.terminationStatus != 0 {
            throw "Wine Crashed! (\(process.terminationStatus))"
        }

        return ""
    }

    static func runWineserver(_ args: [String], bottle: Bottle) throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = wineserverBinary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        process.currentDirectoryURL = binFolder
        process.environment = ["WINEPREFIX": bottle.url.path]

        try process.run()
    }

    static func wineVersion() async throws -> String {
        var output = try await run(["--version"])
        output.replace("wine-", with: "")

        // Deal with WineCX version names
        if let index = output.firstIndex(where: { $0.isWhitespace }) {
            return String(output.prefix(upTo: index))
        }
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
    static func runProgram(program: Program) async throws -> String {
        let arguments = program.settings.arguments.split { $0.isWhitespace }.map(String.init)
        return try await run(["start", "/unix", program.url.path] + arguments,
                             bottle: program.bottle,
                             environment: program.settings.environment)
    }

    static func killBottle(bottle: Bottle) throws {
        return try runWineserver(["-k"], bottle: bottle)
    }
}

extension String: Error {}

enum WineInterfaceError: Error {
    case invalidResponce
}
