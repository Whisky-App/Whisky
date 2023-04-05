//
//  PortableExecutable.swift
//  Whisky
//
//  Created by Isaac Marovitz on 03/04/2023.
//

import Foundation

struct COFFFileHeader: Hashable {
    var resourceSection: ResourceSection?

    init(data: Data) throws {
        var offset: Int = 0x3c
        let signatureOffset = data.extract(UInt16.self, offset: offset)

        offset = Int(signatureOffset)

        if let signature = String(data: data[offset..<offset + 4], encoding: .utf8) {
            if signature != "PE\0\0" {
                throw("File is not a PE")
            }

            offset += 6
            let numberOfSections = data.extract(UInt16.self, offset: offset)

            offset += 14
            let sizeOfOptionalHeader = data.extract(UInt16.self, offset: offset)

            offset += Int(sizeOfOptionalHeader) + 4

            for _ in 0..<numberOfSections - 1 {
                if let name = String(data: data[offset..<offset + 8], encoding: .utf8) {
                    if name.replacingOccurrences(of: "\0", with: "") == ".rsrc" {
                        offset += 20
                        let pointerToRawData = data.extract(UInt32.self, offset: offset)

                        try resourceSection = ResourceSection(data: data, address: pointerToRawData)
                        break
                    }
                }

                offset += 0x28
            }
        }
    }
}

struct ResourceSection: Hashable {
    var rootDirectory: ImageResourceDirectory

    init(data: Data, address: UInt32) throws {
        let offset = Int(address) + 12
        rootDirectory = ImageResourceDirectory(data: data, address: offset, startOfResources: offset)
    }
}

struct ImageResourceDirectory: Hashable {
    var subdirectories: [ImageResourceDirectory] = []
    var rawData: ImageResourceDataEntry?
    let depth: Int

    init(data: Data, address: Int, startOfResources: Int, depth: Int = 0) {
        self.depth = depth
        var offset = address
        let numberOfNameEntries = data.extract(UInt16.self, offset: offset)

        offset += 2
        let numberOfIDEntires = data.extract(UInt16.self, offset: offset)

        offset += 2

        let totalEntries = numberOfNameEntries + numberOfIDEntires
        var numberOfNameEntriesIterated = 0
        for _ in 0..<totalEntries {
            if depth == 0 {
                if numberOfNameEntriesIterated < numberOfNameEntries {
                    numberOfNameEntriesIterated += 1

                    offset += 8
                } else {
                    let name = data.extract(UInt32.self, offset: offset)
                    if ResourceTypes(rawValue: name) == .icon {
                        appendResource(data: data, offset: &offset, startOfResources: startOfResources)
                    } else {
                        offset += 8
                    }
                }
            } else {
                appendResource(data: data, offset: &offset, startOfResources: startOfResources)
            }
        }
    }

    mutating func appendResource(data: Data, offset: inout Int, startOfResources: Int) {
        let offsetToData = data.extract(UInt32.self, offset: offset + 4)
        let offsetToSubdir = (offsetToData << 1) >> 1

        let highBit = offsetToData >> 31
        if highBit != 0 {
            subdirectories.append(ImageResourceDirectory(data: data,
                                                         address: Int(offsetToSubdir) + startOfResources,
                                                         startOfResources: startOfResources,
                                                         depth: depth + 1))
        } else {
            rawData = ImageResourceDataEntry(data: data,
                                             address: Int(offsetToData) + startOfResources)
        }
        offset += 8
    }
}

struct ImageResourceDataEntry: Hashable {
    init(data: Data, address: Int) {
        var offset = address

        let offsetToData = data.extract(UInt32.self, offset: offset)
        offset += 4

        let size = data.extract(UInt32.self, offset: offset)
        // print(offsetToData)
        // print(size)
    }
}

enum ResourceTypes: UInt32 {
    case cursor = 1
    case bitmap = 2
    case icon = 3
    case menu = 4
    case dialog = 5
    case string = 6
    case fontDir = 7
    case font = 8
    case accelerator = 9
    case rcData = 10
    case messageTable = 11
}
