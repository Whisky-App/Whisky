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
    var dxvk: Bool = false
    var winetricks: Bool = false

    func openCDrive() {
        let cDrive = path.appendingPathComponent("drive_c")
        NSWorkspace.shared.activateFileViewerSelecting([cDrive])
    }

    init() {}

    init(path: URL) {
        self.path = path
    }
}
