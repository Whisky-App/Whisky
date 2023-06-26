//
//  Bottle.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation
import AppKit

public class Bottle: Hashable, Identifiable {
    public static func == (lhs: Bottle, rhs: Bottle) -> Bool {
        return lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }
    public var id: URL {
        self.url
    }

    var url: URL = URL.homeDirectory.appending(component: ".wine")
    var settings: BottleSettings
    var programs: [Program] = []
    var startMenuPrograms: [ShellLinkHeader] = []
    var inFlight: Bool = false

    func openCDrive() {
        let cDrive = url.appendingPathComponent("drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([cDrive])
    }

    @discardableResult
    func updateStartMenuPrograms() -> [ShellLinkHeader] {
        let globalStartMenu = url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("ProgramData")
            .appendingPathComponent("Microsoft")
            .appendingPathComponent("Windows")
            .appendingPathComponent("Start Menu")

        let userStartMenu = url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("users")
            .appendingPathComponent("crossover")
            .appendingPathComponent("AppData")
            .appendingPathComponent("Roaming")
            .appendingPathComponent("Microsoft")
            .appendingPathComponent("Windows")
            .appendingPathComponent("Start Menu")
        startMenuPrograms.removeAll()

        var startMenuProgramsURLs: [URL] = []
        let globalEnumerator = FileManager.default.enumerator(at: globalStartMenu,
                                                              includingPropertiesForKeys: [.isRegularFileKey],
                                                              options: [.skipsHiddenFiles])
        while let url = globalEnumerator?.nextObject() as? URL {
            if url.pathExtension == "lnk" {
                startMenuProgramsURLs.append(url)
            }
        }

        let userEnumerator = FileManager.default.enumerator(at: userStartMenu,
                                                              includingPropertiesForKeys: [.isRegularFileKey],
                                                              options: [.skipsHiddenFiles])
        while let url = userEnumerator?.nextObject() as? URL {
            if url.pathExtension == "lnk" {
                startMenuProgramsURLs.append(url)
            }
        }

        startMenuProgramsURLs.sort(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })

        for program in startMenuProgramsURLs {
            do {
                if !startMenuPrograms.contains(where: { $0.url == program }) {
                    try startMenuPrograms.append(ShellLinkHeader(url: program,
                                                                 data: Data(contentsOf: program),
                                                                 bottle: self))
                }
            } catch {
                print(error)
            }
        }

        return startMenuPrograms
    }

    @discardableResult
    func updateInstalledPrograms() -> [Program] {
        let programFiles = url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("Program Files")
        let programFilesx86 = url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("Program Files (x86)")
        programs.removeAll()

        let enumerator64 = FileManager.default.enumerator(at: programFiles,
                                                          includingPropertiesForKeys: [.isExecutableKey],
                                                          options: [.skipsHiddenFiles])
        while let url = enumerator64?.nextObject() as? URL {
            if !url.hasDirectoryPath && url.pathExtension == "exe" {
                programs.append(Program(name: url.lastPathComponent, url: url, bottle: self))
            }
        }

        let enumerator32 = FileManager.default.enumerator(at: programFilesx86,
                                                          includingPropertiesForKeys: [.isExecutableKey],
                                                          options: [.skipsHiddenFiles])
        while let url = enumerator32?.nextObject() as? URL {
            if !url.hasDirectoryPath && url.pathExtension == "exe" {
                programs.append(Program(name: url.lastPathComponent, url: url, bottle: self))
            }
        }

        programs.sort(by: { $0.name.lowercased() < $1.name.lowercased() })
        return programs
    }

    @MainActor
    func delete() {
        do {
            try FileManager.default.removeItem(at: url)
            if let path = BottleVM.shared.bottlesList.paths.firstIndex(of: url) {
                BottleVM.shared.bottlesList.paths.remove(at: path)
            }
            BottleVM.shared.loadBottles()
        } catch {
            print("Failed to delete bottle")
        }
    }

    @MainActor
    func rename(newName: String) {
        settings.name = newName
    }

    init(inFlight: Bool = false) {
        self.settings = BottleSettings(bottleURL: url)
        self.inFlight = inFlight
    }
    init(bottleUrl: URL, inFlight: Bool = false) {
        self.settings = BottleSettings(bottleURL: bottleUrl)
        self.url = bottleUrl
        self.inFlight = inFlight
    }
}

extension Array where Element == Bottle {
    mutating func sortByName() {
        self.sort { $0.settings.name.lowercased() < $1.settings.name.lowercased() }
    }
}

public enum WinVersion: String, CaseIterable, Codable {
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
