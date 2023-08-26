//
//  BottleData.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 26/08/2023.
//

import Foundation
import SemanticVersion

struct BottleEntries: Codable {
	var fileVersion: SemanticVersion = SemanticVersion(1, 0, 0)
	var paths: [URL] = []
}

public class BottleVMEntries {
	static let containerDir = FileManager.default.homeDirectoryForCurrentUser
		.appendingPathComponent("Library")
		.appendingPathComponent("Containers")
		.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky")

	static let bottleEntriesDir = containerDir
		.appendingPathComponent("BottleVM")
		.appendingPathExtension("plist")

	private var file: BottleEntries {
		didSet {
			encode()
		}
	}

	public var paths: [URL] {
		get {
			file.paths
		}
		set {
			file.paths = newValue
		}
	}

	public static func exists() -> Bool {
		return FileManager.default.fileExists(atPath: Self.bottleEntriesDir.path())
	}

	public init() {
		file = .init()
		if !Self.exists() {
			return
		}
		if !decode() {
			encode()
		}
	}

	@discardableResult
	func decode() -> Bool {
		let decoder = PropertyListDecoder()
		do {
			let data = try Data(contentsOf: Self.bottleEntriesDir)
			file = try decoder.decode(BottleEntries.self, from: data)
			if file.fileVersion != BottleEntries().fileVersion {
				print("Invalid file version \(file.fileVersion)")
				return false
			}
			return true
		} catch {
			return false
		}
	}

	@discardableResult
	public func encode() -> Bool {
		let encoder = PropertyListEncoder()
		encoder.outputFormat = .xml

		do {
			let data = try encoder.encode(file)
			try data.write(to: Self.bottleEntriesDir)
			return true
		} catch {
			return false
		}
	}
}
