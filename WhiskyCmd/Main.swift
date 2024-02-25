//
//  Main.swift
//  WhiskyCmd
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
import ArgumentParser
import WhiskyKit
import SwiftyTextTable
import Progress
import SemanticVersion

@main
struct Whisky: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A CLI interface for Whisky.",
        subcommands: [List.self,
                      Create.self,
                      Add.self,
//                      Export.self,
                      Delete.self,
                      Remove.self,
                      Run.self,
                      Shellenv.self
                      /*Install.self,
                      Uninstall.self*/])
}

extension Whisky {
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "List existing bottles.")

        mutating func run() throws {
            var bottlesList = BottleData()
            let bottles = bottlesList.loadBottles()

            let nameCol = TextTableColumn(header: "Name")
            let winVerCol = TextTableColumn(header: "Windows Version")
            let pathCol = TextTableColumn(header: "Path")

            var table = TextTable(columns: [nameCol, winVerCol, pathCol])
            for bottle in bottles {
                table.addRow(values: [bottle.settings.name,
                                      bottle.settings.windowsVersion.pretty(),
                                      bottle.url.prettyPath()])
            }

            print(table.render())
        }
    }

    struct Create: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Create a new bottle.")

        @Argument var name: String

        mutating func run() throws {
            let bottleURL = BottleData.defaultBottleDir.appending(path: UUID().uuidString)

            do {
                try FileManager.default.createDirectory(atPath: bottleURL.path(percentEncoded: false),
                                                        withIntermediateDirectories: true)
                let bottle = Bottle(bottleUrl: bottleURL, inFlight: true)
                // Should allow customisation
                bottle.settings.windowsVersion = .win10
                bottle.settings.name = name
//                try await Wine.changeWinVersion(bottle: bottle, win: winVersion)
//                let wineVer = try await Wine.wineVersion()
                bottle.settings.wineVersion = SemanticVersion(0, 0, 0)

                var bottlesList = BottleData()
                bottlesList.paths.append(bottleURL)
                print("Created new bottle \"\(name)\".")
            } catch {
                print(error)
            }
        }
    }

    struct Add: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Add an existing bottle.")

        @Argument var path: String

        mutating func run() throws {
            // Should be sanitised
            let bottleURL = URL(filePath: path)
            let settings = try BottleSettings.decode(from: bottleURL)
            var bottlesList = BottleData()
            bottlesList.paths.append(bottleURL)
            print("Bottle \"\(settings.name)\" added.")
        }
    }

    struct Export: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Export an existing bottle.")

        mutating func run() throws {
//            print("Create a bottle")
        }
    }

    struct Delete: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Delete an existing bottle from disk.")

        @Argument var name: String

        mutating func run() throws {
            var bottlesList = BottleData()
            let bottles = bottlesList.loadBottles()

            // Should ask for confirmation
            let bottleToRemove = bottles.first(where: { $0.settings.name == name })
            if let bottleToRemove = bottleToRemove {
                bottlesList.paths.removeAll(where: { $0 == bottleToRemove.url })
                do {
                    try FileManager.default.removeItem(at: bottleToRemove.url)
                    print("Deleted \"\(name)\".")
                } catch {
                    print(error)
                }
            } else {
                fputs("No bottle called \"\(name)\" found.\n", stderr)
            }
        }
    }

    struct Remove: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Remove an existing bottle from Whisky.",
                                                        discussion: "This will not remove the bottle from disk.")

        @Argument var name: String

        mutating func run() throws {
            var bottlesList = BottleData()
            let bottles = bottlesList.loadBottles()

            let bottleToRemove = bottles.first(where: { $0.settings.name == name })
            if let bottleToRemove = bottleToRemove {
                bottlesList.paths.removeAll(where: { $0 == bottleToRemove.url })
                print("Removed \"\(name)\".")
            } else {
                fputs("No bottle called \"\(name)\" found.\n", stderr)
            }
        }
    }

    struct Run: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Run a program with Whisky.")

        @Argument var bottleName: String
        @Argument var path: String
        @Argument var args: [String] = []

        mutating func run() throws {
            var bottlesList = BottleData()
            let bottles = bottlesList.loadBottles()

            guard let bottle = bottles.first(where: { $0.settings.name == bottleName }) else {
                fputs("A bottle with that name doesn't exist.\n", stderr)
                return
            }

            let url = URL(fileURLWithPath: path)
            let program = Program(url: url, bottle: bottle)
            program.runInTerminal()
        }
    }

    struct Shellenv: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Prints export statements for a Bottle for eval.")

        @Argument var bottleName: String

        mutating func run() throws {
            var bottlesList = BottleData()
            let bottles = bottlesList.loadBottles()

            guard let bottle = bottles.first(where: { $0.settings.name == bottleName }) else {
                fputs("A bottle with that name doesn't exist.\n", stderr)
                return
            }

            let envCmd = Wine.generateTerminalEnvironmentCommand(bottle: bottle)
            print(envCmd)

        }
    }

    struct Install: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Install Whisky dependencies.")

        @Flag(name: [.long, .short], help: "Download & Install GPTK") var gptk = false

        mutating func run() throws {
//            if gptk {
//                let semaphore = DispatchSemaphore(value: 0)
//
//                Task {
//                    if let info = await GPTKDownloader.getLatestGPTKURL(),
//                       let url = info.directURL {
//                        print("Downloading GPTK from \(url)")
//                        var progress = ProgressBar(count: info.totalByteCount)
//                        let downloadTask = URLSession.shared.downloadTask(with: url) { url, _, _ in
//                            if let url = url {
//                                // tarLocation = url
//                            }
//                            semaphore.signal()
//                        }
//                        var observation = downloadTask.observe(\.countOfBytesReceived) { task, _ in
//                            progress.setValue(Int(task.countOfBytesReceived))
//                        }
//                        downloadTask.resume()
//                    }
//                }
//
//                semaphore.wait()
//            }
        }
    }

    struct Uninstall: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Uninstall Whisky dependencies.",
                                                        discussion: "Uninstalling Wine implicitly uninstalls GPTK.")

        @Flag(name: [.long, .short], help: "Uninstall GPTK") var gptk = false

        mutating func run() throws {
//            if gptk {
//                GPTKInstaller.uninstall()
//                print("GPTK uninstalled.")
//            }
        }
    }
}
