//
//  ShellLink.swift
//  Whisky
//
//  Created by Isaac Marovitz on 01/04/2023.
//

import Foundation
import AppKit

struct ShellLinkHeader: Hashable {
    static func == (lhs: ShellLinkHeader, rhs: ShellLinkHeader) -> Bool {
        lhs.url == rhs.url
    }

    var url: URL
    var linkFlags: LinkFlags
    var linkInfo: LinkInfo?
    var stringData: StringData?

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
            linkInfo = LinkInfo(data: data,
                                bottle: bottle,
                                offset: &offset)
        }

        if linkFlags.contains(.hasIconLocation) {
            stringData = StringData(data: data,
                                    bottle: bottle,
                                    offset: &offset)
        }
    }
}

struct LinkFlags: OptionSet, Hashable {
    let rawValue: UInt32

    static let hasLinkTargetIDList = LinkFlags(rawValue: 1 << 0)
    static let hasLinkInfo = LinkFlags(rawValue: 1 << 1)
    static let hasIconLocation = LinkFlags(rawValue: 1 << 6)
}

struct LinkInfo: Hashable {
    var linkInfoFlags: LinkInfoFlags
    var program: Program?

    init(data: Data, bottle: Bottle, offset: inout Int) {
        let startOfSection = offset

        let linkInfoSize = data.extract(UInt32.self, offset: offset)

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

                program = getProgram(data: data,
                                     offset: localPathOffset,
                                     bottle: bottle,
                                     unicode: true)
            } else {
                offset += 8
                let localBasePathOffset = data.extract(UInt32.self, offset: offset)
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

struct LinkInfoFlags: OptionSet, Hashable {
    let rawValue: UInt32

    static let volumeIDAndLocalBasePath = LinkInfoFlags(rawValue: 1 << 0)
    static let commonNetworkRelativeLinkAndPathSuffix = LinkInfoFlags(rawValue: 1 << 1)
}

struct StringData: Hashable {
    var icon: NSImage?

    // This is a naïve implementation to save my sanity.
    // A real version of this would have to check the LinkFlags to determine
    // which strings exist in this section, and then properly iterate
    // and fine the icon location string. Luckily for us, icon location
    // is the last string that can be in this section so we can be lazy
    init(data: Data, bottle: Bottle, offset: inout Int) {
        let stringData = data[offset...]
        var strings = stringData.nullTerminatedStrings(using: .windowsCP1254)
        strings = strings.joined().components(separatedBy: "\u{01}")

        if let last = strings.last {
            if last.hasSuffix(".ico") {
                if let range = last.range(of: "C:") {
                    var result = String(last[range.lowerBound...])
                    result.replace("\\", with: "/")
                    result.replace("C:", with: "\(bottle.url.path)/drive_c")
                    let iconLocation = URL(filePath: result)

                    do {
                        let data = try Data(contentsOf: iconLocation)
                        if let rep = NSBitmapImageRep(data: data) {
                            icon = NSImage(size: rep.size)
                            icon?.addRepresentation(rep)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
