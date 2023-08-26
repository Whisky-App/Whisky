//
//  Main.swift
//  WhiskyCmd
//
//  Created by Isaac Marovitz on 26/08/2023.
//

import Foundation
import ArgumentParser

@main
struct Whisky: ParsableCommand {
	static var configuration = CommandConfiguration(
		abstract: "A CLI interface for Whisky.",
		subcommands: [Create.self, Delete.self, Remove.self, Install.self, Uninstall.self])
}

extension Whisky {
	struct Create: ParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Create a new bottle.")
		
		mutating func run() throws {
			print("Create a bottle")
		}
	}

	struct Delete: ParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Deletes bottle with given name.")
		
		mutating func run() throws {
			print("Delete a bottle")
		}
	}

	struct Remove: ParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Removes bottle with given name from Whisky, but does not delete it from disk.")
		
		mutating func run() throws {
			print("Remove a bottle")
		}
	}

	struct Install: ParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Install Whisky dependencies.")
		
		@Flag(name: [.long, .short], help: "Download & Install Wine") var wine = false
		@Option(name: [.long, .short], help: "Install GPTK from .dmg") var gptk: String?
		
		mutating func run() throws {
			print("Install deps")
		}
	}

	struct Uninstall: ParsableCommand {
		static var configuration = CommandConfiguration(abstract: "Uninstall Whisky dependencies.", 
														discussion: "Uninstalling Wine implicitly uninstall GPTK.")
		
		@Flag(name: [.long, .short], help: "Uninstall Wine") var wine = false
		@Flag(name: [.long, .short], help: "Uninstall GPTK") var gptk = false
		
		mutating func run() throws {
			print("Uninstall deps")
		}
	}
}
