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
        return lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(url)
    }

    var name: String {
        url.lastPathComponent
    }

    var url: URL = URL.homeDirectory.appending(component: ".wine")
    var settings: BottleSettings
    var programs: [URL] = []
    var startMenuPrograms: [ShellLinkHeader] = []

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
            .appendingPathComponent(NSUserName())
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
                try startMenuPrograms.append(ShellLinkHeader(url: program,
                                                             data: Data(contentsOf: program),
                                                             bottle: self))
            } catch {
                print(error)
            }
        }

        return startMenuPrograms
    }

    @discardableResult
    func updateInstalledPrograms() -> [URL] {
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
                programs.append(url)
            }
        }

        let enumerator32 = FileManager.default.enumerator(at: programFilesx86,
                                                          includingPropertiesForKeys: [.isExecutableKey],
                                                          options: [.skipsHiddenFiles])
        while let url = enumerator32?.nextObject() as? URL {
            if !url.hasDirectoryPath && url.pathExtension == "exe" {
                programs.append(url)
            }
        }

        programs.sort(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() })
        return programs
    }

    func enableDXVK() {
        let enumerator64 = FileManager.default.enumerator(at: Wine.dxvkFolder
                                                                .appendingPathComponent("x64"),
                                                          includingPropertiesForKeys: [.isRegularFileKey])

        while let url = enumerator64?.nextObject() as? URL {
            if url.pathExtension == "dll" {
                let system32 = self.url
                    .appendingPathComponent("drive_c")
                    .appendingPathComponent("windows")
                    .appendingPathComponent("system32")

                let original = system32
                    .appendingPathComponent(url.lastPathComponent)

                do {
                    try FileManager.default.moveItem(at: original,
                                                     to: original.appendingPathExtension("bak"))
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
                let syswow64 = self.url
                    .appendingPathComponent("drive_c")
                    .appendingPathComponent("windows")
                    .appendingPathComponent("syswow64")

                let original = syswow64
                    .appendingPathComponent(url.lastPathComponent)

                do {
                    try FileManager.default.moveItem(at: original,
                                                     to: original.appendingPathExtension("bak"))
                    try FileManager.default.copyItem(at: url,
                                                     to: original)
                } catch {
                    print("Failed to replace \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    func disableDXVK() {
        let system32 = self.url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("windows")
            .appendingPathComponent("system32")

        let enumerator64 = FileManager.default.enumerator(at: system32,
                                                          includingPropertiesForKeys: [.isRegularFileKey])

        while let url = enumerator64?.nextObject() as? URL {
            if url.pathExtension == "bak" {
                let dxvk = url.deletingPathExtension()
                do {
                    try FileManager.default.removeItem(at: dxvk)
                    try FileManager.default.moveItem(at: url, to: dxvk)

                } catch {
                    print("Failed to replace \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        let syswow64 = self.url
            .appendingPathComponent("drive_c")
            .appendingPathComponent("windows")
            .appendingPathComponent("syswow64")

        let enumerator32 = FileManager.default.enumerator(at: syswow64,
                                                          includingPropertiesForKeys: [.isRegularFileKey])

        while let url = enumerator32?.nextObject() as? URL {
            if url.pathExtension == "bak" {
                let dxvk = url.deletingPathExtension()
                do {
                    try FileManager.default.removeItem(at: dxvk)
                    try FileManager.default.moveItem(at: url, to: dxvk)
                } catch {
                    print("Failed to replace \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    func delete() {
        do {
            try FileManager.default.removeItem(at: url)
            BottleVM.shared.loadBottles()
        } catch {
            print("Failed to delete bottle")
        }
    }

    @MainActor
    func rename(newName: String) {
        let oldPlist = url.appendingPathComponent(name)
                          .appendingPathExtension("plist")
        let newPlist = url.appendingPathComponent(newName)
                          .appendingPathExtension("plist")

        let oldFolder = url
        let newFolder = url.deletingLastPathComponent()
                           .appendingPathComponent(newName)

        do {
            try FileManager.default.moveItem(at: oldPlist, to: newPlist)
            try FileManager.default.moveItem(at: oldFolder, to: newFolder)
            BottleVM.shared.loadBottles()
        } catch {
            print(error)
        }
    }

    init() {
        self.settings = BottleSettings(bottleUrl: url,
                                             name: url.lastPathComponent)
    }

    init(path: URL) {
        self.url = path
        self.settings = BottleSettings(bottleUrl: url,
                                             name: url.lastPathComponent)
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
