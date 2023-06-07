//
//  Registry.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import Foundation

public class Registry: Hashable {
    let data: IniConfig
    
    public static func == (lhs: Registry, rhs: Registry) -> Bool {
        return lhs.data == rhs.data
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(data)
    }
    
    init(bottle: Bottle) async {
        data = [:]
        let program = Program(name: "reg.exe",
                              url: bottle.url.appendingPathExtension(""),
                              bottle: bottle)
    }
}
