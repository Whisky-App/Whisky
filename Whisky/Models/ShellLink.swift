//
//  ShellLink.swift
//  Whisky
//
//  Created by Isaac Marovitz on 01/04/2023.
//

import Foundation

struct ShellLinkHeader {
    var linkFlags: LinkFlags
    var linkInfo: LinkInfo?

    init(data: Data) {
        var offset: Int = 0
        let headerSize = data.extract(UInt32.self)
        // Move past headerSize, and linkCLSID
        offset += 4 + 16
        let rawLinkFlags = data.extract(UInt32.self, offset: offset)
        linkFlags = LinkFlags(rawValue: rawLinkFlags)

        offset = Int(headerSize)
        if linkFlags.contains(.hasLinkTargetIDList) {
            offset += Int(data.extract(UInt16.self, offset: offset)) + 2
        }

        if linkFlags.contains(.hasLinkInfo) {
            linkInfo = LinkInfo(data: data, offset: &offset)
        }
    }
}

struct LinkFlags: OptionSet {
    let rawValue: UInt32

    static let hasLinkTargetIDList = LinkFlags(rawValue: 1 << 0)
    static let hasLinkInfo = LinkFlags(rawValue: 1 << 1)
}

struct LinkInfo {
    var linkInfoFlags: LinkInfoFlags

    init(data: Data, offset: inout Int) {
        let startOfSection = offset
        offset += 8

        let rawLinkInfoFlags = data.extract(UInt32.self, offset: offset)
        linkInfoFlags = LinkInfoFlags(rawValue: rawLinkInfoFlags)

        if linkInfoFlags.contains(.volumeIDAndLocalBasePath) {
            offset += 8
            let localBasePathOffset = data.extract(UInt32.self, offset: offset)
            let localPathOffset = startOfSection + Int(localBasePathOffset)

            let pathData = data[localPathOffset...]
            if let nullRange = pathData.firstIndex(of: 0) {
                let string = String(data: pathData[..<nullRange], encoding: .utf8)
                print(string ?? "Invalid string")
            }
        }
    }
}

struct LinkInfoFlags: OptionSet {
    let rawValue: UInt32

    static let volumeIDAndLocalBasePath = LinkInfoFlags(rawValue: 1 << 0)
    static let commonNetworkRelativeLinkAndPathSuffix = LinkInfoFlags(rawValue: 1 << 1)
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
