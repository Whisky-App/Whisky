//
//  PortableExecutable+COFFFileHeader.swift
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
    /// COFF File Header (Object and Image)
    ///
    /// https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#coff-file-header-object-and-image
    public struct COFFFileHeader: Hashable, Equatable, Sendable {
        public let machine: UInt16
        public let numberOfSections: UInt16
        public let timeDateStamp: Date
        public let pointerToSymbolTable: UInt32
        public let numberOfSymbols: UInt32
        public let sizeOfOptionalHeader: UInt16
        public let characteristics: UInt16

        init(handle: FileHandle, offset: UInt64) {
            var offset = offset + 4 // Skip signature

            self.machine = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2

            self.numberOfSections = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2

            let timeDateStamp = handle.extract(UInt32.self, offset: offset) ?? 0
            self.timeDateStamp = Date(timeIntervalSince1970: TimeInterval(timeDateStamp))
            offset += 4

            self.pointerToSymbolTable = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4

            self.numberOfSymbols = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4

            self.sizeOfOptionalHeader = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2

            self.characteristics = handle.extract(UInt16.self, offset: offset) ?? 0
            offset += 2
        }
    }
}
