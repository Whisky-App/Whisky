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

    @discardableResult
    static func run(_ args: [String],
                    bottle: Bottle? = nil,
                    environment: [String: String]? = nil) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        let output = WineOutput()
        guard let log = Log(bottle: bottle,
                            args: args,
                            environment: environment) else {
            return ""
        }

        process.executableURL = wineBinary
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        process.currentDirectoryURL = binFolder
        pipe.fileHandleForReading.readabilityHandler = { pipe in
            let line = String(decoding: pipe.availableData, as: UTF8.self)
            Task.detached {
                await output.append(line)
            }
            log.write(line: "\(line)", printLine: false)
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
        log.write(line: "Launched Wine (\(process.processIdentifier))\n")

        process.waitUntilExit()
        log.write(line: "Process exited with code \(process.terminationStatus)")

        if process.terminationStatus != 0 {
            throw "Wine Crashed! (\(process.terminationStatus))"
        }

        return await output.output
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

    static func buildVersion(bottle: Bottle) async throws -> String {
        let output = try await run(["reg",
                                    "query",
                                    #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                                    "-v", "CurrentBuild"], bottle: bottle)
        let lines = output.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
        if let line = lines.first(where: { $0.contains("REG_SZ") }) {
            let array = line.split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            if let buildNumber = array.last {
                return String(buildNumber)
            }
        }

        throw WineInterfaceError.invalidResponce
    }

    @discardableResult
    static func control(bottle: Bottle) async throws -> String {
        return try await run(["control"], bottle: bottle)
    }

    @discardableResult
    static func regedit(bottle: Bottle) async throws -> String {
        return try await run(["regedit"], bottle: bottle)
    }

    @discardableResult
    static func cfg(bottle: Bottle) async throws -> String {
        return try await run(["winecfg"], bottle: bottle)
    }

    @discardableResult
    static func changeWinVersion(bottle: Bottle, win: WinVersion) async throws -> String {
        return try await run(["winecfg", "-v", win.rawValue], bottle: bottle)
    }

    static func changeBuildVersion(bottle: Bottle, version: Int) async throws {
        try await run(["reg", "add",
                       #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                       "-v",
                       "CurrentBuild", "-t", "REG_SZ", "-d", "\(version)", "-f"], bottle: bottle)
        try await run(["reg", "add",
                       #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                       "-v",
                       "CurrentBuildNumber", "-t", "REG_SZ", "-d", "\(version)", "-f"], bottle: bottle)
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

actor WineOutput {
    var output: String = ""

    func append(_ line: String) {
        output.append(line)
    }
}
