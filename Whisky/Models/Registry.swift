//
//  Registry.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//

import Foundation
import AppKit

public class Registry: Hashable {
    public struct Entries: Hashable {
        public var system: RegistryConfig
        public var user: RegistryConfig
        public var userDefines: RegistryConfig

        public static func == (lhs: Entries, rhs: Entries) -> Bool {
            return lhs.system == rhs.system && lhs.user == rhs.user && lhs.userDefines == rhs.userDefines
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(system)
            hasher.combine(user)
            return hasher.combine(userDefines)
        }

        init(systemRegistryPath sysReg: URL, userRegistryPath userReg: URL, userDefinesRegistryPath userDefReg: URL) {
//            let parse = { (_ url: URL) in
//                do {
//                    return try parseINIFile(url)
//                } catch Error(let err) {
//                    DispatchQueue.main.async {
//                        let alert = NSAlert()
//                        alert.messageText = NSLocalizedString("registry.loadfailed", comment: "")
//                        alert.informativeText = NSLocalizedString(err, comment: "")
//                        alert.alertStyle = .critical
//
//                        alert.addButton(withTitle: "Aw, damn")
//                        alert.runModal()
//                    }
//
//                    return [:]
//                }
//            }


            // swiftlint:disable force_try
            print("Loading inis: \(sysReg), \(userReg), \(userDefReg)")
            do {
                system = try parseRegistryFile(sysReg)
                user = try parseRegistryFile(userReg)
                userDefines = try parseRegistryFile(userDefReg)
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("registry.loadfailed", comment: "")
                    alert.informativeText = NSLocalizedString("button.loadfailed.info", comment: "")
                    alert.alertStyle = .critical

                    alert.addButton(withTitle: "Ok")
                    alert.runModal()
                }

                system = [:]
                user = [:]
                userDefines = [:]
            }
        }

        init(system: RegistryConfig, user: RegistryConfig, userDefines: RegistryConfig) {
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

    public var entries: Entries

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
