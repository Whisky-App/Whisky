//
//  PortableExecutable.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 03/04/2023.
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
    public let data: Data?

    init(data: Data, offset: Int) {
        var offset = offset
        self.name = String(data: data[offset..<offset + 8], encoding: .utf8) ?? ""
        offset += 8
        self.virtualSize = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.virtualAddress = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfRawData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.pointerToRawData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.pointerToRelocations = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.pointerToLineNumbers = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.numberOfRelocations = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.numberOfLineNumbers = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.characteristics = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        if sizeOfRawData > 0 {
            let dataOffset = Int(pointerToRawData)
            self.data = data.subdata(in: dataOffset..<dataOffset+Int(sizeOfRawData))
        } else {
            self.data = nil
        }
    }
}

public struct SectionTable: Hashable {
    public let sections: [PESection]

    init(data: Data, offset: Int, numberOfSections: Int) {
        var sections = [PESection]()
        var offset = offset
        for _ in 0..<numberOfSections {
            let section = PESection(data: data, offset: offset)
            sections.append(section)
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

    init(data: Data) throws {
        var offset = 0x3C
        let peOffset = data.extract(UInt32.self, offset: offset) ?? 0
        offset = Int(peOffset)

        offset += 4
        let machine = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let numberOfSections = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let timeDateStamp = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let pointerToSymbolTable = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let numberOfSymbols = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        let sizeOfOptionalHeader = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        let characteristics = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        self.machine = machine
        self.numberOfSections = numberOfSections
        self.timeDateStamp = timeDateStamp
        self.pointerToSymbolTable = pointerToSymbolTable
        self.numberOfSymbols = numberOfSymbols
        self.sizeOfOptionalHeader = sizeOfOptionalHeader
        self.characteristics = characteristics

        self.optionalHeader = OptionalHeader(data: data, offset: offset)
        offset += Int(sizeOfOptionalHeader)

        self.sectionTable = SectionTable(data: data, offset: offset, numberOfSections: Int(numberOfSections))
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
    init(data: Data, offset: Int) {
        var offset = offset
        self.magic = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorLinkerVersion = data.extract(UInt8.self, offset: offset) ?? 0
        offset += 1
        self.minorLinkerVersion = data.extract(UInt8.self, offset: offset) ?? 0
        offset += 1
        self.sizeOfCode = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfInitializedData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfUninitializedData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.addressOfEntryPoint = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.baseOfCode = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.baseOfData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.imageBase = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sectionAlignment = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.fileAlignment = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.majorOperatingSystemVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorOperatingSystemVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorImageVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorImageVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.majorSubsystemVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorSubsystemVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.win32VersionValue = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfImage = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeaders = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.checkSum = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.subsystem = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.dllCharacteristics = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.sizeOfStackReserve = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfStackCommit = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeapReserve = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.sizeOfHeapCommit = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.loaderFlags = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.numberOfRvaAndSizes = data.extract(UInt32.self, offset: offset) ?? 0
    }
}

public struct PEFile: Hashable {
    public let coffFileHeader: COFFFileHeader
    public let resourceSection: ResourceSection?

    public init(data: Data) throws {
        // Verify it is a PE file by checking for the PE header
        let offsetToPEHeader = data.extract(UInt32.self, offset: 0x3C) ?? 0
        let peHeader = data.extract(UInt32.self, offset: Int(offsetToPEHeader))
        guard peHeader == 0x4550 else {
            throw PEError.invalidPEFile
        }
        coffFileHeader = try COFFFileHeader(data: data)
        resourceSection = try ResourceSection(data: data,
                                              sectionTable: coffFileHeader.sectionTable,
                                              imageBase: coffFileHeader.optionalHeader.imageBase)
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
