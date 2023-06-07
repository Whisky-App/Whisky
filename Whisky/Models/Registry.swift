//
//  Registry.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import Foundation

public class Registry: Hashable {
    public struct Entries: Hashable {
        public let system: IniConfig
        public let user: IniConfig
        public let userDefines: IniConfig

        public static func == (lhs: Entries, rhs: Entries) -> Bool {
            return lhs.system == rhs.system && lhs.user == rhs.user && lhs.userDefines == rhs.userDefines
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(system)
            hasher.combine(user)
            return hasher.combine(userDefines)
        }

        init(systemRegistryPath sysReg: URL, userRegistryPath userReg: URL, userDefinesRegistryPath userDefReg: URL) {
            system = parseIniConfig(sysReg)
            user = parseIniConfig(userReg)
            userDefines = parseIniConfig(userDefReg)
        }
        
        init(system: IniConfig, user: IniConfig, userDefines: IniConfig) {
            self.system = system
            self.user = user
            self.userDefines = userDefines
        }

        init() {
            system = [:]
            user = [:]
            userDefines = [:]
        }
    }

    public let entries: Entries

    public static func == (lhs: Registry, rhs: Registry) -> Bool {
        return lhs.entries == rhs.entries
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(entries)
    }

    init(mockData: Entries) {
        entries = mockData
    }

    init(bottleUrl: URL) {
        entries = Entries(systemRegistryPath: bottleUrl.appending(component: "system.reg"),
                          userRegistryPath: bottleUrl.appending(component: "user.reg"),
                          userDefinesRegistryPath: bottleUrl.appending(component: "userdef.reg"))
    }
}
