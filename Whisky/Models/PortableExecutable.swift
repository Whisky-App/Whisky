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
                        offset += 16
                        let sizeOfRawData = data.extract(UInt32.self, offset: offset)

                        offset += 4
                        let pointerToRawData = data.extract(UInt32.self, offset: offset)

                        try _ = ResourceSection(data: data, address: pointerToRawData)
                        break
                    }
                }

                offset += 0x28
            }
        }
    }
}

struct ResourceSection: Hashable {
    init(data: Data, address: UInt32) throws {
        let offset = Int(address) + 12
        ImageResourceDirectory(data: data, address: offset, startOfResources: offset)
    }
}

struct ImageResourceDirectory: Hashable {
    init(data: Data, address: Int, startOfResources: Int) {
        var offset = address
        let numberOfNameEntries = data.extract(UInt16.self, offset: offset)

        offset += 2
        let numberOfIDEntires = data.extract(UInt16.self, offset: offset)

        offset += 2

        let totalEntries = numberOfNameEntries + numberOfIDEntires
        for _ in 0..<totalEntries {
            let name = data.extract(UInt32.self, offset: offset)
            let offsetToData = data.extract(UInt32.self, offset: offset + 4)

            let highBit = offsetToData >> 31
            if highBit != 0 {
                let offsetToSubdir = (offsetToData << 1) >> 1
                ImageResourceDirectory(data: data,
                                       address: Int(offsetToSubdir) + startOfResources,
                                       startOfResources: startOfResources)
            } else {
                print("Points to raw data")
            }
            offset += 8
        }
    }
}

extension Int {
    func printHex() {
        var hex = String(format: "%02X", self)
        print("0x\(hex)")
    }
}
