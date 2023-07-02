//
//  Wine.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

struct WineCrashError: Error, CustomStringConvertible {
    let output: String?
    let description: String

    init( description: String, output: String? = nil) {
        self.output = output
        self.description = description
    }
}

class Wine {
    static let binFolder: URL = WineInstaller.libraryFolder
        .appendingPathComponent("Wine")
        .appendingPathComponent("bin")

    static let dxvkFolder: URL = WineInstaller.libraryFolder
        .appendingPathComponent("DXVK")

    static let wineBinary: URL = binFolder
        .appendingPathComponent("wine64")

    static let wineserverBinary: URL = binFolder
        .appendingPathComponent("wineserver")

    // swiftlint:disable function_body_length
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

            if bottle.settings.dxvk {
                enableDXVK(bottle: bottle)
            }

            process.environment = env
        }

        try process.run()
        var isRunning = true
        log.write(line: "Launched Wine (\(process.processIdentifier))\n")

        while isRunning {
            process.waitUntilExit()
            if pipe.fileHandleForReading.availableData.count == 0 {
                isRunning = false
            }
        }
        log.write(line: "Process exited with code \(process.terminationStatus)")
        _ = try pipe.fileHandleForReading.readToEnd()

        if process.terminationStatus != 0 {
            let crashOutput = await output.output
            throw WineCrashError( description: "Wine Crashed! (\(process.terminationStatus))", output: crashOutput)
        }

        return await output.output
    }

    // swiftlint:enable function_body_length
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
        return try await queryRegistyKey(bottle: bottle,
                                  key: #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                                  name: "CurrentBuild",
                                  type: .string)
    }

    static func retinaMode(bottle: Bottle) async throws -> Bool {
        let output = try await queryRegistyKey(bottle: bottle,
                                        key: #"HKCU\Software\Wine\Mac Driver"#,
                                        name: "RetinaMode",
                                        type: .string)
        if output == "" {
            try await changeRetinaMode(bottle: bottle, retinaMode: false)
        }
        return output == "y"
    }

    static func changeRetinaMode(bottle: Bottle, retinaMode: Bool) async throws {
        try await addRegistyKey(bottle: bottle,
                                key: #"HKCU\Software\Wine\Mac Driver"#,
                                name: "RetinaMode",
                                data: retinaMode ? "y" : "n",
                                type: .string)
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

    static func addRegistyKey(bottle: Bottle, key: String, name: String,
                              data: String, type: RegistryType) async throws {
        try await run(["reg", "add", key, "-v", name,
                       "-t", type.rawValue, "-d", data, "-f"], bottle: bottle)
    }

    static func queryRegistyKey(bottle: Bottle, key: String, name: String,
                                type: RegistryType, defaultValue: String? = "") async throws -> String {
        do {
            let output = try await run(["reg", "query", key, "-v", name], bottle: bottle)
            let lines = output.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
            if let line = lines.first(where: { $0.contains(type.rawValue) }) {
                let array = line.split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
                if let value = array.last {
                    return String(value)
                }
            }
        } catch let error as WineCrashError {
            if let output = error.output {
                if output.contains("Unable to find the specified registry key") {
                    return defaultValue ?? ""
                }
            }
            throw error
        }

        throw WineInterfaceError.invalidResponce
    }

    static func changeBuildVersion(bottle: Bottle, version: Int) async throws {
        try await addRegistyKey(bottle: bottle, key: #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                                name: "CurrentBuild", data: "\(version)", type: .string)
        try await addRegistyKey(bottle: bottle, key: #"HKLM\Software\Microsoft\Windows NT\CurrentVersion"#,
                                name: "CurrentBuildNumber", data: "\(version)", type: .string)
    }

    @discardableResult
    static func runProgram(program: Program) async throws -> String {
        let arguments = program.settings.arguments.split { $0.isWhitespace }.map(String.init)
        return try await run(["start", program.url.windowsPath()] + arguments,
                             bottle: program.bottle,
                             environment: program.settings.environment)
    }

    @discardableResult
    static func runExternalProgram(url: URL, bottle: Bottle) async throws -> String {
        return try await run(["start", "/unix", url.path],
                             bottle: bottle)
    }

    static func killBottle(bottle: Bottle) throws {
        return try runWineserver(["-k"], bottle: bottle)
    }

    static func enableDXVK(bottle: Bottle) {
        let enumerator64 = FileManager.default.enumerator(at: Wine.dxvkFolder
                                                                .appendingPathComponent("x64"),
                                                          includingPropertiesForKeys: [.isRegularFileKey])

        while let url = enumerator64?.nextObject() as? URL {
            if url.pathExtension == "dll" {
                let system32 = bottle.url
                    .appendingPathComponent("drive_c")
                    .appendingPathComponent("windows")
                    .appendingPathComponent("system32")

                let original = system32
                    .appendingPathComponent(url.lastPathComponent)

                do {
                    try FileManager.default.removeItem(at: original)
                    try FileManager.default.copyItem(at: url,
                                                     to: original)
                } catch {
                    print("Failed to replace \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        let enumerator32 = FileManager.default.enumerator(at: Wine.dxvkFolder
                                                                .appendingPathComponent("x32"),
                                                          includingPropertiesForKeys: [.isRegularFileKey])

        while let url = enumerator32?.nextObject() as? URL {
            if url.pathExtension == "dll" {
                let syswow64 = bottle.url
                    .appendingPathComponent("drive_c")
                    .appendingPathComponent("windows")
                    .appendingPathComponent("syswow64")

                let original = syswow64
                    .appendingPathComponent(url.lastPathComponent)

                do {
                    try FileManager.default.removeItem(at: original)
                    try FileManager.default.copyItem(at: url,
                                                     to: original)
                } catch {
                    print("Failed to replace \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }
}

extension String: Error {}

enum WineInterfaceError: Error {
    case invalidResponce
}

enum RegistryType: String {
    case binary = "REG_BINARY"
    case dword = "REG_DWORD"
    case qword = "REG_QWORD"
    case string = "REG_SZ"
}

actor WineOutput {
    var output: String = ""

    func append(_ line: String) {
        output.append(line)
    }
}
