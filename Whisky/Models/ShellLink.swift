//
//  ShellLink.swift
//  Whisky
//
//  Created by Isaac Marovitz on 01/04/2023.
//

import Foundation

struct ShellLinkHeader: Hashable {
    static func == (lhs: ShellLinkHeader, rhs: ShellLinkHeader) -> Bool {
        lhs.url == rhs.url
    }

    var url: URL
    var linkFlags: LinkFlags
    var linkInfo: LinkInfo?

    init(url: URL, data: Data, bottle: Bottle) {
        self.url = url
        var offset: Int = 0
        let headerSize = data.extract(UInt32.self)
        // Move past headerSize, and linkCLSID
        offset += 4 + 16
        let rawLinkFlags = data.extract(UInt32.self, offset: offset)
        linkFlags = LinkFlags(rawValue: rawLinkFlags)

        offset = Int(headerSize)
        if linkFlags.contains(.hasLinkTargetIDList) {
            // We don't need this section so just get the size, and skip ahead
            offset += Int(data.extract(UInt16.self, offset: offset)) + 2
        }

        if linkFlags.contains(.hasLinkInfo) {
            linkInfo = LinkInfo(data: data, bottle: bottle, offset: &offset)
        }
    }
}

struct LinkFlags: OptionSet, Hashable {
    let rawValue: UInt32

    static let hasLinkTargetIDList = LinkFlags(rawValue: 1 << 0)
    static let hasLinkInfo = LinkFlags(rawValue: 1 << 1)
}

struct LinkInfo: Hashable {
    var linkInfoFlags: LinkInfoFlags
    var linkDestination: URL?

    init(data: Data, bottle: Bottle, offset: inout Int) {
        let startOfSection = offset

        offset += 4
        let linkInfoHeaderSize = data.extract(UInt32.self, offset: offset)

        offset += 4
        let rawLinkInfoFlags = data.extract(UInt32.self, offset: offset)
        linkInfoFlags = LinkInfoFlags(rawValue: rawLinkInfoFlags)

        if linkInfoFlags.contains(.volumeIDAndLocalBasePath) {
            if linkInfoHeaderSize >= 0x00000024 {
                offset += 20
                let localBasePathOffsetUnicode = data.extract(UInt32.self, offset: offset)
                let localPathOffset = startOfSection + Int(localBasePathOffsetUnicode)

                linkDestination = getURL(data: data,
                                         offset: localPathOffset,
                                         bottle: bottle,
                                         unicode: true)
            } else {
                offset += 8
                let localBasePathOffset = data.extract(UInt32.self, offset: offset)
                let localPathOffset = startOfSection + Int(localBasePathOffset)

                linkDestination = getURL(data: data,
                                         offset: localPathOffset,
                                         bottle: bottle,
                                         unicode: false)
            }
        }
    }

    func getURL(data: Data, offset: Int, bottle: Bottle, unicode: Bool) -> URL? {
        let pathData = data[offset...]
        if let nullRange = pathData.firstIndex(of: 0) {
            let encoding: String.Encoding = unicode ? .utf16 : .windowsCP1254
            if var string = String(data: pathData[..<nullRange], encoding: encoding) {
                // UNIX-ify the path
                string.replace("\\", with: "/")
                string.replace("C:", with: "\(bottle.url.path)/drive_c")
                print(string)
                return URL(filePath: string)
            }
        }

        return nil
    }
}

struct LinkInfoFlags: OptionSet, Hashable {
    let rawValue: UInt32

    static let volumeIDAndLocalBasePath = LinkInfoFlags(rawValue: 1 << 0)
    static let commonNetworkRelativeLinkAndPathSuffix = LinkInfoFlags(rawValue: 1 << 1)
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
