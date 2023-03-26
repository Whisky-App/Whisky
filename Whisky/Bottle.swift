//
//  Bottle.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation
import AppKit

public class Bottle: Hashable {
    public static func == (lhs: Bottle, rhs: Bottle) -> Bool {
        return lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(path)
    }

    var name: String {
        path.lastPathComponent
    }

    var path: URL = URL.homeDirectory.appending(component: ".wine")
    var winVersion: WinVersion = .win7
    var dxvk: Bool = false
    var winetricks: Bool = false
    var programs: [URL] = []

    func openCDrive() {
        let cDrive = path.appendingPathComponent("drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([cDrive])
    }

    @discardableResult
    func updateInstalledPrograms() -> [URL] {
        let programFiles = path
            .appendingPathComponent("drive_c")
            .appendingPathComponent("Program Files")
        let programFilesx86 = path
            .appendingPathComponent("drive_c")
            .appendingPathComponent("Program Files (x86)")
        programs.removeAll()

        let enumerator = FileManager.default.enumerator(at: programFiles,
                                                        includingPropertiesForKeys: [.isExecutableKey],
                                                        options: [.skipsHiddenFiles])
        while let url = enumerator?.nextObject() as? URL {
            if !url.hasDirectoryPath {
                programs.append(url)
            }
        }

        let enumerator2 = FileManager.default.enumerator(at: programFilesx86,
                                                        includingPropertiesForKeys: [.isExecutableKey],
                                                        options: [.skipsHiddenFiles])
        while let url = enumerator2?.nextObject() as? URL {
            if !url.hasDirectoryPath {
                programs.append(url)
            }
        }

        return programs
    }

    @MainActor
    func delete() {
        do {
            try FileManager.default.removeItem(at: path)
            BottleVM.shared.loadBottles()
        } catch {
            print("Failed to delete bottle")
        }
    }

    init() {}

    init(path: URL) {
        self.path = path
    }
}

public enum WinVersion: String, CaseIterable {
    case winXP = "winxp64"
    case win7 = "win7"
    case win8 = "win8"
    case win81 = "win81"
    case win10 = "win10"

    func pretty() -> String {
        switch self {
        case .winXP:
            return "Windows XP"
        case .win7:
            return "Windows 7"
        case .win8:
            return "Windows 8"
        case .win81:
            return "Windows 8.1"
        case .win10:
            return "Windows 10"
        }
    }
}
