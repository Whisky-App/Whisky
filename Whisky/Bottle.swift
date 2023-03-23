//
//  Bottle.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import Foundation

struct Bottle: Hashable {
    var name: String
    var dxvk: Bool = false
    var winetricks: Bool = false

    init(_ name: String, dxvk: Bool = false, winetricks: Bool = false) {
        self.name = name
        self.dxvk = dxvk
        self.winetricks = winetricks
    }
}
