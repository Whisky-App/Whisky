//
//  ShellLink.swift
//  Whisky
//
//  Created by Isaac Marovitz on 01/04/2023.
//

import Foundation

struct ShellLinkHeader {
    var linkFlags: [LinkFlags] = []
    var linkInfo: LinkInfo?

    init(data: Data) {
        let rawLinkFlags = data.extract(UInt32.self, offset: 0x0014)

        for flag in LinkFlags.allCases {
            if let index = flag.index {
                let unusedBits = 32 - 1 - LinkFlags.allCases.count
                let shift = LinkFlags.allCases.count + unusedBits - index

                if ((rawLinkFlags.byteSwapped & flag.rawValue) >> shift) == 1 {
                    linkFlags.append(flag)
                    print(flag)
                }
            }
        }

        if linkFlags.contains(.hasLinkInfo) {
            // linkInfo = LinkInfo(data: data)
        }
    }
}

enum LinkFlags: UInt32, CaseIterable {
    case hasLinkTargetIDList = 0x80000000
    case hasLinkInfo = 0x40000000
    case hasName = 0x20000000
    case hasRelativePath = 0x10000000

    case hasWorkingDir = 0x8000000
    case hasArguments = 0x4000000
    case hasIconLocation = 0x2000000
    case isUnicode = 0x1000000

    case forceNoLinkInfo = 0x800000
    case hasExpString = 0x400000
    case runInSeperateProcess = 0x200000
    case unused1 = 0x100000

    case hasDarwinID = 0x80000
    case runAsUser = 0x40000
    case hasExpIcon  = 0x20000
    case noPidlAlias = 0x10000

    case unused2 = 0x8000
    case runWithShimLayer = 0x4000
    case forceNoLinkTrack = 0x2000
    case enableTargetMetadata = 0x1000

    case disableLinkPathTracking = 0x800
    case disableKnownFolderTracking = 0x400
    case disableKnownFolderAlias = 0x200
    case allowLinkToLink = 0x100

    case unaliasOnSave = 0x80
    case preferEnvironmentPath = 0x40
    case keepLocalIDListForUNCTarget = 0x20
}

struct LinkInfo {
    var linkInfoFlags: [LinkInfoFlags] = []

    init(data: Data) {
        let rawLinkInfoFlags = data.extract(UInt32.self, offset: 0x0113)
        print(rawLinkInfoFlags)

        for flag in linkInfoFlags {
            if let index = flag.index {
                let unusedBits = 32 - 1 - LinkInfoFlags.allCases.count
                let shift = LinkFlags.allCases.count + unusedBits - index

                if ((rawLinkInfoFlags.byteSwapped & flag.rawValue) >> shift) == 1 {
                    linkInfoFlags.append(flag)
                    print(flag)
                }
            }
        }
    }
}

enum LinkInfoFlags: UInt32, CaseIterable {
    case volumeIDAndLocalBasePath = 0x80000000
    case commonNetworkRelativeLinkAndPathSuffix = 0x40000000
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
