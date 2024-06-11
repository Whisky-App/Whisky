//
//  PortableExecutable.swift
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
import AppKit

public struct PEError: Error {
    public let message: String

    static let invalidPEFile = PEError(message: "Invalid PE file")
}

public enum Architecture: Hashable {
    case x32
    case x64
    case unknown

    public func toString() -> String? {
        switch self {
        case .x32:
            return "32-bit"
        case .x64:
            return "64-bit"
        default:
            return nil
        }
    }
}

/// Microsoft Portable Executable
///
/// https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
public struct PEFile: Hashable, Equatable, Sendable {
    /// URL to the file
    public let url: URL
    /// COFF File Header (Object and Image)
    public let coffFileHeader: COFFFileHeader
    /// The Optional Header
    public let optionalHeader: OptionalHeader?
    /// The Section Table (Section Headers)
    public let sections: [Section]

    public init?(url: URL?) throws {
        guard let url else { return nil }
        try self.init(url: url)
    }

    public init(url: URL) throws {
        self.url = url
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer {
            try? fileHandle.close()
        }

        // (0x3C) Pointer to PE Header
        guard let peOffset = fileHandle.extract(UInt32.self, offset: 0x3C) else {
            throw PEError.invalidPEFile
        }
        var offset = UInt64(peOffset)
        guard let peHeader = fileHandle.extract(UInt32.self, offset: offset) else {
            throw PEError.invalidPEFile
        }
        // Check signature ("PE\0\0")
        guard peHeader.bigEndian == 0x50450000 else {
            throw PEError.invalidPEFile
        }

        let coffFileHeader = COFFFileHeader(handle: fileHandle, offset: offset)
        offset += 24 // Size of COFFHeader
        self.coffFileHeader = coffFileHeader

        if coffFileHeader.sizeOfOptionalHeader > 0 {
            self.optionalHeader = OptionalHeader(handle: fileHandle, offset: offset)
            offset += UInt64(coffFileHeader.sizeOfOptionalHeader)
        } else {
            self.optionalHeader = nil
        }

        var sections: [Section] = []
        for _ in 0..<coffFileHeader.numberOfSections {
            if let section = Section(handle: fileHandle, offset: offset) {
                sections.append(section)
            }
            offset += 40 // Size of Section
        }
        self.sections = sections
    }

    /// The ``Architecture`` of the executable
    public var architecture: Architecture {
        switch optionalHeader?.magic {
        case .pe32:
            return .x32
        case .pe32Plus:
            return .x64
        default:
            return .unknown
        }
    }

    /// Read the resource section
    /// 
    /// - Parameters:
    ///   - handle: The `FileHandle` to read the resource table section from.
    ///   - types: Only read entrys of the given types. Only applies to the root table. Default includes all types.
    /// - Returns: The resource table section
    private func rsrc(handle: FileHandle, types: [ResourceType] = ResourceType.allCases) -> ResourceDirectoryTable? {
        if let resourceSection = sections.first(where: { $0.name == ".rsrc" }) {
            return ResourceDirectoryTable(
                handle: handle,
                pointerToRawData: UInt64(resourceSection.pointerToRawData),
                types: types
            )
        } else {
            return nil
        }
    }

    /// The Resource Directory Table
    public var rsrc: ResourceDirectoryTable? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer {
            try? handle.close()
        }

        return rsrc(handle: handle)
    }

    /// The best icon for this executable
    /// - Returns: An `NSImage` if there is a renderable icon in the resource directory table
    public func bestIcon() -> NSImage? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer {
            try? handle.close()
        }

        guard let rsrc = rsrc(handle: handle, types: [.icon]) else { return nil }
        let icons = rsrc.allEntries
            .compactMap { entry -> NSImage? in
                guard let offset = entry.resolveRVA(sections: sections) else { return nil }
                let bitmapInfo = BitmapInfoHeader(handle: handle, offset: UInt64(offset))
                if bitmapInfo.size != 40 {
                    do {
                        try handle.seek(toOffset: UInt64(offset))
                        if let iconData = try handle.read(upToCount: Int(entry.size)) {
                            if let rep = NSBitmapImageRep(data: iconData) {
                                let image = NSImage(size: rep.size)
                                image.addRepresentation(rep)
                                return image
                            }
                        }
                    } catch {
                        print("Failed to get icon")
                    }
                } else if bitmapInfo.colorFormat != .unknown {
                    return bitmapInfo.renderBitmap(handle: handle, offset: UInt64(offset + bitmapInfo.size))
                }

                return nil
            }
            .filter { $0.isValid }

        if !icons.isEmpty {
            return icons.max(by: { $0.size.height < $1.size.height })
        } else {
            return NSImage()
        }
    }
}
