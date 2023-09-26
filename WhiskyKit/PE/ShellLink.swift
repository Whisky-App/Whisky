//
//  ShellLink.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import AppKit

public struct ShellLinkHeader {
    public static func getProgram(url: URL, data: Data, bottle: Bottle) -> Program? {
        var offset: Int = 0
        let headerSize = data.extract(UInt32.self) ?? 0
        // Move past headerSize and linkCLSID
        offset += 4 + 16
        let rawLinkFlags = data.extract(UInt32.self, offset: offset) ?? 0
        let linkFlags = LinkFlags(rawValue: rawLinkFlags)

        offset = Int(headerSize)
        if linkFlags.contains(.hasLinkTargetIDList) {
            // We don't need this section so just get the size, and skip ahead
            offset += Int(data.extract(UInt16.self, offset: offset) ?? 0) + 2
        }

        if linkFlags.contains(.hasLinkInfo) {
            let linkInfo = LinkInfo(data: data,
                                    bottle: bottle,
                                    offset: &offset)
            return linkInfo.program
        } else {
            return nil
        }
    }
}

public struct LinkFlags: OptionSet, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    static let hasLinkTargetIDList = LinkFlags(rawValue: 1 << 0)
    static let hasLinkInfo = LinkFlags(rawValue: 1 << 1)
    static let hasIconLocation = LinkFlags(rawValue: 1 << 6)
}

public struct LinkInfo: Hashable {
    public var linkInfoFlags: LinkInfoFlags
    public var program: Program?

    public init(data: Data, bottle: Bottle, offset: inout Int) {
        let startOfSection = offset

        let linkInfoSize = data.extract(UInt32.self, offset: offset) ?? 0

        offset += 4
        let linkInfoHeaderSize = data.extract(UInt32.self, offset: offset) ?? 0

        offset += 4
        let rawLinkInfoFlags = data.extract(UInt32.self, offset: offset) ?? 0
        linkInfoFlags = LinkInfoFlags(rawValue: rawLinkInfoFlags)

        if linkInfoFlags.contains(.volumeIDAndLocalBasePath) {
            if linkInfoHeaderSize >= 0x00000024 {
                offset += 20
                let localBasePathOffsetUnicode = data.extract(UInt32.self, offset: offset) ?? 0
                let localPathOffset = startOfSection + Int(localBasePathOffsetUnicode)

                program = getProgram(data: data,
                                     offset: localPathOffset,
                                     bottle: bottle,
                                     unicode: true)
            } else {
                offset += 8
                let localBasePathOffset = data.extract(UInt32.self, offset: offset) ?? 0
                let localPathOffset = startOfSection + Int(localBasePathOffset)

                program = getProgram(data: data,
                                     offset: localPathOffset,
                                     bottle: bottle,
                                     unicode: false)
            }
        }

        offset = startOfSection + Int(linkInfoSize)
    }

    func getProgram(data: Data, offset: Int, bottle: Bottle, unicode: Bool) -> Program? {
        let pathData = data[offset...]
        if let nullRange = pathData.firstIndex(of: 0) {
            let encoding: String.Encoding = unicode ? .utf16 : .windowsCP1254
            if var string = String(data: pathData[..<nullRange], encoding: encoding) {
                // UNIX-ify the path
                string.replace("\\", with: "/")
                string.replace("C:", with: "\(bottle.url.path)/drive_c")
                let url = URL(filePath: string)
                return Program(name: url.lastPathComponent, url: url, bottle: bottle)
            }
        }

        return nil
    }
}

public struct LinkInfoFlags: OptionSet, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    static let volumeIDAndLocalBasePath = LinkInfoFlags(rawValue: 1 << 0)
    static let commonNetworkRelativeLinkAndPathSuffix = LinkInfoFlags(rawValue: 1 << 1)
}
