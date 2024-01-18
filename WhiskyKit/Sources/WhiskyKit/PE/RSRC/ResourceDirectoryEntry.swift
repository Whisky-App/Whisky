//
//  ResourceDirectoryEntry.swift
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

/// The directory entries make up the rows of a table.
///
/// https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#resource-directory-entries
public enum ResourceDirectoryEntry {
    public struct ID { // swiftlint:disable:this type_name
        public let type: ResourceType
        private let rawOffset: UInt32

        init(handle: FileHandle, offset: UInt64) {
            var offset = offset
            let rawType = handle.extract(UInt32.self, offset: offset) ?? 0
            self.type = ResourceType(rawValue: rawType) ?? .unknown
            offset += 4
            self.rawOffset = handle.extract(UInt32.self, offset: offset) ?? 0
            offset += 4
        }

        /// Check if the entry is a directory entry
        var isDirectory: Bool {
            (rawOffset & 0x80000000) != 0
        }

        /// The offset of the entry
        var offset: UInt32 {
            if isDirectory {
                return rawOffset & 0x7FFFFFFF
            } else {
                return rawOffset
            }
        }
    }
}
