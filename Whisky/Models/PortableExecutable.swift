//
//  PortableExecutable.swift
//  Whisky
//
//  Created by Isaac Marovitz on 03/04/2023.
//

import Foundation

struct COFFFileHeader: Hashable {
    init(data: Data) throws {
        var offset: Int = 0x3c
        let signatureOffset = data.extract(UInt16.self, offset: offset)

        offset = Int(signatureOffset)

        if let signature = String(data: data[offset..<offset + 4], encoding: .utf8) {
            if signature != "PE\0\0" {
                throw("File is not a PE")
            }

            offset += 4
            let coffOffset = offset

            offset += 16
            let sizeOfOptionalHeader = data.extract(UInt16.self, offset: offset)

            if sizeOfOptionalHeader > 0 {
                offset = coffOffset + 20
                let magic = data.extract(UInt16.self, offset: offset)
                if magic == 0x10b {
                    // PE32
                    offset += 112
                    let resourceTableAddress = data.extract(UInt32.self, offset: offset)

                    offset += 4
                    let resourceTableSize = data.extract(UInt32.self, offset: offset)

                    try ResourceSection(data: data,
                                        address: resourceTableAddress,
                                        size: resourceTableSize)
                } else if magic == 0x20b {
                    // PE32+
                    offset += 128
                    let resourceTableAddress = data.extract(UInt32.self, offset: offset)

                    offset += 4
                    let resourceTableSize = data.extract(UInt32.self, offset: offset)

                    try ResourceSection(data: data,
                                        address: resourceTableAddress,
                                        size: resourceTableSize)
                } else {
                    throw("Could not find magic number in Optional Header")
                }
            }
        }
    }
}

struct ResourceSection: Hashable {
    init(data: Data, address: UInt32, size: UInt32) throws {
        // TODO
    }
}
