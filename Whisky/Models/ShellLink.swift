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
        linkFlags = LinkFlags(rawValue: rawLinkFlags.byteSwapped)

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

    static let hasLinkTargetIDList = LinkFlags(rawValue: 1 << 31)
    static let hasLinkInfo = LinkFlags(rawValue: 1 << 30)
    static let hasName = LinkFlags(rawValue: 1 << 29)
    static let hasRelativePath = LinkFlags(rawValue: 1 << 28)

    static let hasWorkingDir = LinkFlags(rawValue: 1 << 27)
    static let hasArguments = LinkFlags(rawValue: 1 << 26)
    static let hasIconLocation = LinkFlags(rawValue: 1 << 25)
    static let isUnicode = LinkFlags(rawValue: 1 << 24)

    static let forceNoLinkInfo = LinkFlags(rawValue: 1 << 23)
    static let hasExpString = LinkFlags(rawValue: 1 << 22)
    static let runInSeperateProcess = LinkFlags(rawValue: 1 << 21)
    static let unused1 = LinkFlags(rawValue: 1 << 20)

    static let hasDarwinID = LinkFlags(rawValue: 1 << 19)
    static let runAsUser = LinkFlags(rawValue: 1 << 18)
    static let hasExpIcon  = LinkFlags(rawValue: 1 << 17)
    static let noPidlAlias = LinkFlags(rawValue: 1 << 16)

    static let unused2 = LinkFlags(rawValue: 1 << 15)
    static let runWithShimLayer = LinkFlags(rawValue: 1 << 14)
    static let forceNoLinkTrack = LinkFlags(rawValue: 1 << 13)
    static let enableTargetMetadata = LinkFlags(rawValue: 1 << 12)

    static let disableLinkPathTracking = LinkFlags(rawValue: 1 << 11)
    static let disableKnownFolderTracking = LinkFlags(rawValue: 1 << 10)
    static let disableKnownFolderAlias = LinkFlags(rawValue: 1 << 9)
    static let allowLinkToLink = LinkFlags(rawValue: 1 << 8)

    static let unaliasOnSave = LinkFlags(rawValue: 1 << 7)
    static let preferEnvironmentPath = LinkFlags(rawValue: 1 << 6)
    static let keepLocalIDListForUNCTarget = LinkFlags(rawValue: 1 << 5)
}

struct LinkInfo {
    var linkInfoFlags: LinkInfoFlags

    init(data: Data, offset: inout Int) {
        offset += 8

        let rawLinkInfoFlags = data.extract(UInt32.self, offset: offset)
        linkInfoFlags = LinkInfoFlags(rawValue: rawLinkInfoFlags.byteSwapped)
    }
}

struct LinkInfoFlags: OptionSet {
    let rawValue: UInt32

    static let volumeIDAndLocalBasePath = LinkInfoFlags(rawValue: 1 << 31)
    static let commonNetworkRelativeLinkAndPathSuffix = LinkInfoFlags(rawValue: 1 << 30)
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
