//
//  Main.swift
//  WhiskyCmd
//
//  Created by Isaac Marovitz on 26/08/2023.
//

import Foundation
import ArgumentParser
import WhiskyKit

@main
struct Whisky: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A CLI interface for Whisky.",
        subcommands: [List.self,
                      Create.self,
                      Add.self,
                      Export.self,
                      Delete.self,
                      Remove.self,
                      Install.self,
                      Uninstall.self])
}

extension Whisky {
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "List existing bottles.")

        mutating func run() throws {
            let bottlesList = BottleData()
            var bottles: [BottleSettings] = []

            bottles = bottlesList.paths.map({
                BottleSettings(bottleURL: $0)
            })

            // Columns should be even and automatic
            print("| Name | Windows Version |")
            for bottle in bottles {
                print("| \(bottle.name) | \(bottle.windowsVersion.pretty()) |")
            }
        }
    }

    struct Create: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Create a new bottle.")

        mutating func run() throws {
            print("Create a bottle")
        }
    }

    struct Add: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Add an existing bottle.")

        @Argument var path: String

        mutating func run() throws {
            // Should be sanitised
            let bottle = URL(filePath: path)
            let settings = BottleSettings(bottleURL: bottle)
            var bottlesList = BottleData()
            bottlesList.paths.append(bottle)
            print("Bottle \"\(settings.name)\" added.")
        }
    }

    struct Export: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Export an existing bottle.")

        mutating func run() throws {
            print("Create a bottle")
        }
    }

    struct Delete: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Delete a an existing bottle from disk.")

        mutating func run() throws {
            print("Delete a bottle")
        }
    }

    struct Remove: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Remove an existing bottle from Whisky.",
                                                        discussion: "This will not remove the bottle from disk.")

        @Argument var name: String

        mutating func run() throws {
            let bottlesList = BottleData()
            var bottles: [BottleSettings] = []

            bottles = bottlesList.paths.map({
                BottleSettings(bottleURL: $0)
            })

            let bottleToRemove = bottles.first(where: { $0.name == name })
            if let bottleToRemove = bottleToRemove {
                // bottlesList.paths.remove(at: 0)
            } else {
                print("No bottle called \"\(name)\" found.")
            }
        }
    }

    struct Install: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Install Whisky dependencies.")

        @Flag(name: [.long, .short], help: "Download & Install Wine") var wine = false

        mutating func run() throws {
            print("Install deps")
        }
    }

    struct Uninstall: ParsableCommand {
        static var configuration = CommandConfiguration(abstract: "Uninstall Whisky dependencies.",
                                                        discussion: "Uninstalling Wine implicitly uninstalls GPTK.")

        @Flag(name: [.long, .short], help: "Uninstall Wine") var wine = false

        mutating func run() throws {
            print("Uninstall deps")
        }
    }
}
