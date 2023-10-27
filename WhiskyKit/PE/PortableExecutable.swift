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

public struct PESection: Hashable {
    public let name: String
    public let virtualSize: UInt32
    public let virtualAddress: UInt32
    public let sizeOfRawData: UInt32
    public let pointerToRawData: UInt32
    public let pointerToRelocations: UInt32
    public let pointerToLineNumbers: UInt32
    public let numberOfRelocations: UInt16
    public let numberOfLineNumbers: UInt16
    public let characteristics: UInt32
    // public let data: Data?

    init?(handle: FileHandle, offset: Int) throws {
        var offset = offset
        try handle.seek(toOffset: UInt64(offset))
        if let nameData = try handle.read(upToCount: 8) {
            self.name = String(data: nameData, encoding: .utf8) ?? ""
        } else {
            self.name = ""
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
        self.pointerToLineNumbers = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.numberOfRelocations = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.numberOfLineNumbers = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.characteristics = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
//        if sizeOfRawData > 0 {
//            let dataOffset = Int(pointerToRawData)
//            self.data = data.subdata(in: dataOffset..<dataOffset+Int(sizeOfRawData))
//        } else {
//            self.data = nil
//        }
    }
}

public struct SectionTable: Hashable {
    public let sections: [PESection]

    init(handle: FileHandle, offset: Int, numberOfSections: Int) {
        var sections = [PESection]()
        var offset = offset
        for _ in 0..<numberOfSections {
            do {
                if let section = try PESection(handle: handle, offset: offset) {
                    sections.append(section)
                }
            } catch {
                print("Failed to get section name!")
            }
            offset += 40
        }
        self.sections = sections
    }
}

public struct COFFFileHeader: Hashable {
    public let machine: UInt16
    public let numberOfSections: UInt16
    public let timeDateStamp: UInt32
    public let pointerToSymbolTable: UInt32
    public let numberOfSymbols: UInt32
    public let sizeOfOptionalHeader: UInt16
    public let characteristics: UInt16
    public let sectionTable: SectionTable
    public let optionalHeader: OptionalHeader

    init(handle: FileHandle) throws {
        var offset = 0x3C
        let peOffset = handle.extract(UInt32.self, offset: offset) ?? 0
        offset = Int(peOffset)

        offset += 4
        let machine = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let numberOfSections = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let timeDateStamp = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let pointerToSymbolTable = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let numberOfSymbols = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let sizeOfOptionalHeader = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let characteristics = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        self.machine = machine
        self.numberOfSections = numberOfSections
        self.timeDateStamp = timeDateStamp
        self.pointerToSymbolTable = pointerToSymbolTable
        self.numberOfSymbols = numberOfSymbols
        self.sizeOfOptionalHeader = sizeOfOptionalHeader
        self.characteristics = characteristics

        self.optionalHeader = OptionalHeader(handle: handle, offset: offset)
        offset += Int(sizeOfOptionalHeader)

        self.sectionTable = SectionTable(handle: handle, offset: offset, numberOfSections: Int(numberOfSections))
    }
}

public struct OptionalHeader: Hashable {
    public let magic: UInt16
    public let majorLinkerVersion: UInt8
    public let minorLinkerVersion: UInt8
    public let sizeOfCode: UInt32
    public let sizeOfInitializedData: UInt32
    public let sizeOfUninitializedData: UInt32
    public let addressOfEntryPoint: UInt32
    public let baseOfCode: UInt32
    public let baseOfData: UInt32
    public let imageBase: UInt32
    public let sectionAlignment: UInt32
    public let fileAlignment: UInt32
    public let majorOperatingSystemVersion: UInt16
    public let minorOperatingSystemVersion: UInt16
    public let majorImageVersion: UInt16
    public let minorImageVersion: UInt16
    public let majorSubsystemVersion: UInt16
    public let minorSubsystemVersion: UInt16
    public let win32VersionValue: UInt32
    public let sizeOfImage: UInt32
    public let sizeOfHeaders: UInt32
    public let checkSum: UInt32
    public let subsystem: UInt16
    public let dllCharacteristics: UInt16
    public let sizeOfStackReserve: UInt32
    public let sizeOfStackCommit: UInt32
    public let sizeOfHeapReserve: UInt32
    public let sizeOfHeapCommit: UInt32
    public let loaderFlags: UInt32
    public let numberOfRvaAndSizes: UInt32

    // swiftlint:disable:next function_body_length
    init(handle: FileHandle, offset: Int) {
        var offset = offset
        self.magic = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorLinkerVersion = handle.extract(UInt8.self, offset: offset) ?? 0
        offset += 1
        self.minorLinkerVersion = handle.extract(UInt8.self, offset: offset) ?? 0
        offset += 1
        self.sizeOfCode = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfInitializedData = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfUninitializedData = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.addressOfEntryPoint = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.baseOfCode = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.baseOfData = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.imageBase = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sectionAlignment = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.fileAlignment = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.majorOperatingSystemVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorOperatingSystemVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorImageVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorImageVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorSubsystemVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorSubsystemVersion = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.win32VersionValue = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfImage = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeaders = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.checkSum = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.subsystem = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.dllCharacteristics = handle.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.sizeOfStackReserve = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfStackCommit = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeapReserve = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeapCommit = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.loaderFlags = handle.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.numberOfRvaAndSizes = handle.extract(UInt32.self, offset: offset) ?? 0
    }
}

public enum Architecture: UInt16, Hashable {
    case x32 = 0x010b
    case x64 = 0x020b
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

public struct PEFile: Hashable {
    public let coffFileHeader: COFFFileHeader
    public var resourceSection: ResourceSection? {
        do {
            return try ResourceSection(handle: handle,
                                       sectionTable: coffFileHeader.sectionTable,
                                       imageBase: coffFileHeader.optionalHeader.imageBase)
        } catch {
            return nil
        }
    }
    public var architecture: Architecture {
        Architecture(rawValue: coffFileHeader.optionalHeader.magic) ?? .unknown
    }
    private let handle: FileHandle

    public init(handle: FileHandle) throws {
        self.handle = handle
        // Verify it is a PE file by checking for the PE header
        let offsetToPEHeader = handle.extract(UInt32.self, offset: 0x3C) ?? 0
        let peHeader = handle.extract(UInt32.self, offset: Int(offsetToPEHeader))
        guard peHeader == 0x4550 else {
            throw PEError.invalidPEFile
        }
        coffFileHeader = try COFFFileHeader(handle: handle)
    }

    public func bestIcon() -> NSImage? {
        var icons: [NSImage] = []
        if let resourceSection = resourceSection {
            for entries in resourceSection.allEntries where entries.icon.isValid {
                icons.append(entries.icon)
            }
        } else {
            print("No resource section")
        }

        if icons.count > 0 {
            return icons.max(by: { $0.size.height < $1.size.height })
        }

        return NSImage()
    }
}
