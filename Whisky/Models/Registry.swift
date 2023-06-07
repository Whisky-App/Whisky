//
//  Registry.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import Foundation

public class Registry: Hashable {
    static let dumpName = "WHISKY_REGISTRY_DUMP.reg"
    
    public let entries: [IniConfig]
    
    public static func == (lhs: Registry, rhs: Registry) -> Bool {
        return lhs.entries == rhs.entries
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(entries)
    }
    
    init(bottle: Bottle) async throws {
        var ents: [IniConfig] = []
        
        for entryFile in [ bottle.url.appending(component: "system.reg"), bottle.url.appending(component: "user.reg"), bottle.url.appending(component: "userdef.reg") ] as [URL] {
            ents.append(parseIniConfig(entryFile))
        }
        
        entries = ents
    }
}
