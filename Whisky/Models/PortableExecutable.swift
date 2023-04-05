//
//  PortableExecutable.swift
//  Whisky
//
//  Created by Isaac Marovitz on 03/04/2023.
//

import Foundation

struct PEError: Error {
    var message: String

    static let invalidPEFile = PEError(message: "Invalid PE file")
}

struct PESection: Hashable, Identifiable {
    var id: String { name }
    var name: String
    var nameAsUInt64: UInt64
    var virtualSize: UInt32
    var virtualAddress: UInt32
    var sizeOfRawData: UInt32
    var pointerToRawData: UInt32
    var pointerToRelocations: UInt32
    var pointerToLineNumbers: UInt32
    var numberOfRelocations: UInt16
    var numberOfLineNumbers: UInt16
    var characteristics: UInt32
    var data: Data?

    init(data: Data, offset: Int) {
        var offset = offset
        nameAsUInt64 = data.extract(UInt64.self, offset: offset)
        self.name = String(data: Data(bytes: &nameAsUInt64, count: 8), encoding: .utf8) ?? ""
        offset += 8
        self.virtualSize = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.virtualAddress = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfRawData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.pointerToRawData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.pointerToRelocations = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.pointerToLineNumbers = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.numberOfRelocations = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.numberOfLineNumbers = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.characteristics = data.extract(UInt32.self, offset: offset)
        offset += 4
        if sizeOfRawData > 0 {
            let dataOffset = Int(pointerToRawData)
            self.data = data.subdata(in: dataOffset..<dataOffset+Int(sizeOfRawData))
        }
    }
}

struct SectionTable: Hashable {
    var sections: [PESection]

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

struct COFFFileHeader: Hashable {
    var machine: UInt16
    var numberOfSections: UInt16
    var timeDateStamp: UInt32
    var pointerToSymbolTable: UInt32
    var numberOfSymbols: UInt32
    var sizeOfOptionalHeader: UInt16
    var characteristics: UInt16
    var sectionTable: SectionTable
    var optionalHeader: OptionalHeader

    init(data: Data) throws {
        var offset = 0x3C
        let peOffset = data.extract(UInt32.self, offset: offset)
        offset = Int(peOffset)

        offset += 4
        let machine = data.extract(UInt16.self, offset: offset)
        offset += 2

        let numberOfSections = data.extract(UInt16.self, offset: offset)
        offset += 2

        let timeDateStamp = data.extract(UInt32.self, offset: offset)
        offset += 4

        let pointerToSymbolTable = data.extract(UInt32.self, offset: offset)
        offset += 4

        let numberOfSymbols = data.extract(UInt32.self, offset: offset)
        offset += 4

        let sizeOfOptionalHeader = data.extract(UInt16.self, offset: offset)
        offset += 2

        let characteristics = data.extract(UInt16.self, offset: offset)
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

struct OptionalHeader: Hashable {
    var magic: UInt16
    var majorLinkerVersion: UInt8
    var minorLinkerVersion: UInt8
    var sizeOfCode: UInt32
    var sizeOfInitializedData: UInt32
    var sizeOfUninitializedData: UInt32
    var addressOfEntryPoint: UInt32
    var baseOfCode: UInt32
    var baseOfData: UInt32
    var imageBase: UInt32
    var sectionAlignment: UInt32
    var fileAlignment: UInt32
    var majorOperatingSystemVersion: UInt16
    var minorOperatingSystemVersion: UInt16
    var majorImageVersion: UInt16
    var minorImageVersion: UInt16
    var majorSubsystemVersion: UInt16
    var minorSubsystemVersion: UInt16
    var win32VersionValue: UInt32
    var sizeOfImage: UInt32
    var sizeOfHeaders: UInt32
    var checkSum: UInt32
    var subsystem: UInt16
    var dllCharacteristics: UInt16
    var sizeOfStackReserve: UInt32
    var sizeOfStackCommit: UInt32
    var sizeOfHeapReserve: UInt32
    var sizeOfHeapCommit: UInt32
    var loaderFlags: UInt32
    var numberOfRvaAndSizes: UInt32

    // swiftlint:disable:next function_body_length
    init(data: Data, offset: Int) {
        var offset = offset
        self.magic = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.majorLinkerVersion = data.extract(UInt8.self, offset: offset)
        offset += 1
        self.minorLinkerVersion = data.extract(UInt8.self, offset: offset)
        offset += 1
        self.sizeOfCode = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfInitializedData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfUninitializedData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.addressOfEntryPoint = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.baseOfCode = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.baseOfData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.imageBase = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sectionAlignment = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.fileAlignment = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.majorOperatingSystemVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.minorOperatingSystemVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.majorImageVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.minorImageVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.majorSubsystemVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.minorSubsystemVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.win32VersionValue = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfImage = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfHeaders = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.checkSum = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.subsystem = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.dllCharacteristics = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.sizeOfStackReserve = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfStackCommit = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfHeapReserve = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.sizeOfHeapCommit = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.loaderFlags = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.numberOfRvaAndSizes = data.extract(UInt32.self, offset: offset)
    }
}

struct PEFile: Hashable {
    var coffFileHeader: COFFFileHeader
    var resourceSection: ResourceSection?

    init(data: Data) throws {
        // Verify it is a PE file by checking for the PE header
        let offsetToPEHeader = data.extract(UInt32.self, offset: 0x3C)
        let peHeader = data.extract(UInt32.self, offset: Int(offsetToPEHeader))
        guard peHeader == 0x4550 else {
            throw PEError.invalidPEFile
        }
        coffFileHeader = try COFFFileHeader(data: data)
        resourceSection = try ResourceSection(data: data, sectionTable: coffFileHeader.sectionTable)
    }
}
