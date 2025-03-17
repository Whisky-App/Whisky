//
//  PortableExecutable+Section.swift
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

extension PEFile {
    /// Section Table (Section Headers)
    ///
    /// https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#section-table-section-headers
    public struct Section: Hashable, Equatable, Sendable {
        public let name: String
        public let virtualSize: UInt32
        public let virtualAddress: UInt32
        public let sizeOfRawData: UInt32
        public let pointerToRawData: UInt32
        public let pointerToRelocations: UInt32
        public let pointerToLinenumbers: UInt32
        public let numberOfRelocations: UInt16
        public let numberOfLineNumbers: UInt16
        public let characteristics: UInt32

        init?(handle: FileHandle, offset: UInt64) {
            var offset = offset

            do {
                try handle.seek(toOffset: UInt64(offset))
                if let data = try handle.read(upToCount: 8) {
                    let string = String(data: data, encoding: .utf8) ?? String()
                    self.name = string.replacingOccurrences(of: "\0", with: "")
                } else {
                    self.name = ""
                }
            } catch {
                return nil
            }

            offset += 8
            self.virtualSize = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.virtualAddress = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.sizeOfRawData = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.pointerToRawData = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.pointerToRelocations = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.pointerToLinenumbers = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
            self.numberOfRelocations = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2
            self.numberOfLineNumbers = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2
            self.characteristics = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
        }
    }
}
