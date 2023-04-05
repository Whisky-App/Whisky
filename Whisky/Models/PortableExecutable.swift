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

            for index in 0..<numberOfSections - 1 {
                if let name = String(data: data[offset..<offset + 8], encoding: .utf8) {
                    if name.replacingOccurrences(of: "\0", with: "") == ".rsrc" {
                        print("Hallelujah")
                    }
                }

                offset += 0x28
            }
        }
    }
}

struct ResourceSection: Hashable {
    init(data: Data, address: UInt32, size: UInt32) throws {
        var offset: Int = Int(address)
        print(address)
        // let numberOfNameEntries = data.extract(UInt16.self, offset: offset)

        offset += 2
        // let numberOfIDEntires = data.extract(UInt16.self, offset: offset)

        offset += 2
        // let nameOffset = data.extract(UInt32.self, offset: offset)
        // print(offset)

        print("\n")
    }
}

extension Int {
    func printHex() {
        var hex = String(format: "%02X", self)
        print("0x\(hex)")
    }
}
