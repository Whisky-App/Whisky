//
//  ResourceSection.swift
//  PEInfo
//
//  Created by Venti on 05/04/2023.
//

import Foundation
import AppKit

// Windows uses 3: Type - Name - Language
// Resource Directory Entries
// 4 bytes: Name offset OR 4 bytes: Integer ID
// 4 bytes: Offset to Data OR 4 bytes: Offset to Subdirectory **HIGH BIT 1**

struct ResourceDirectoryEntry: Hashable, Identifiable {
    var id: UInt32
    var name: String
    var offsetToData: UInt32
    var offsetToSubdirectory: UInt32
    var dataIsDirectory: Bool

    init(data: Data, offset: Int) {
        var offset = offset
        let nameOffsetOrId = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.offsetToData = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.dataIsDirectory = (offsetToData & 0x80000000) != 0
        self.offsetToSubdirectory = offsetToData & 0x7FFFFFFF
        self.id = nameOffsetOrId
        self.name = String(format: "%08X", nameOffsetOrId)
    }
}

struct ResourceDataEntry: Hashable, Identifiable {
    var id: String { name }
    var name: String
    var dataRVA: UInt32
    var size: UInt32
    var codePage: UInt32
    var reserved: UInt32
    var icons: [NSImage] = []

    init(data: Data, offset: Int, name: String, sectionTable: SectionTable) {
        self.name = name
        var offset = offset
        self.dataRVA = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.size = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.codePage = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.reserved = data.extract(UInt32.self, offset: offset)
        offset += 4

        if let offsetToData = resolveRVA(data: data, rva: dataRVA, sectionTable: sectionTable) {
            if offsetToData > data.count || offsetToData + size > data.count {
                print("Failed to resolve RVA correctly")
                print("0x\(String(format: "%08X", offsetToData)), RVA: 0x\(String(format: "%08X", dataRVA))")
            } else {
                let data = data.subdata(in: Int(offsetToData)..<Int(offsetToData + size))
                if let rep = NSBitmapImageRep(data: data) {
                    let icon = NSImage(size: rep.size)
                    icon.addRepresentation(rep)
                    icons.append(icon)
                }
            }
        } else {
            print("Failed to resolve RVA")
        }
    }

    func resolveRVA(data: Data, rva: UInt32, sectionTable: SectionTable) -> UInt32? {
        for section in sectionTable.sections {
            if section.virtualAddress <= rva && rva < (section.virtualAddress + section.virtualSize) {
                return section.pointerToRawData + (rva - section.virtualAddress)
            }
        }

        return nil
    }
}

struct ResourceDirectoryTable: Hashable, Identifiable {
    var id: String { name }
    var name: String
    var characteristics: UInt32
    var timeDateStamp: UInt32
    var majorVersion: UInt16
    var minorVersion: UInt16
    var numberOfNamedEntries: UInt16
    var numberOfIdEntries: UInt16
    var subtables: [ResourceDirectoryTable]
    var entries: [ResourceDataEntry]

    init(data: Data, offset: Int, name: String, sectionTable: SectionTable) {
        self.name = name
        var offset = offset
        self.characteristics = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.timeDateStamp = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.majorVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.minorVersion = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.numberOfNamedEntries = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.numberOfIdEntries = data.extract(UInt16.self, offset: offset)
        offset += 2
        self.subtables = []
        self.entries = []

        var numberOfNamedEntriesIterated = 0
        for _ in 0..<numberOfNamedEntries + numberOfIdEntries {
            if name == "root" && numberOfNamedEntriesIterated < numberOfNamedEntries {
                // We don't care about named entries
                // the entries we're looking for are ID'd
                numberOfNamedEntriesIterated += 1
                offset += 8
                continue
            }

            let entry = ResourceDirectoryEntry(data: data, offset: offset)
            offset += 8
            if entry.dataIsDirectory {
                // In the root directory, we only want to append entries of type icon
                if name == "root" {
                    if ResourceTypes(rawValue: entry.id) == .icon {
                        self.subtables.append(ResourceDirectoryTable(data: data,
                                                                     offset: Int(entry.offsetToSubdirectory),
                                                                     name: entry.name,
                                                                     sectionTable: sectionTable))
                    }
                } else {
                    self.subtables.append(ResourceDirectoryTable(data: data,
                                                                 offset: Int(entry.offsetToSubdirectory),
                                                                 name: entry.name,
                                                                 sectionTable: sectionTable))
                }
            } else {
                self.entries.append(ResourceDataEntry(data: data,
                                                      offset: Int(entry.offsetToData),
                                                      name: entry.name,
                                                      sectionTable: sectionTable))
            }
        }
    }
}

// swiftlint:disable line_length
struct ResourceSection: Hashable {
    /*
    Resources are indexed by a multiple-level binary-sorted tree structure. The general design can incorporate 2**31 levels. By convention, however, Windows uses three levels:

    Type Name Language
    A series of resource directory tables relates all of the levels in the following way: Each directory table is followed by a series of directory entries that give the name or identifier (ID) for that level (Type, Name, or Language level) and an address of either a data description or another directory table. If the address points to a data description, then the data is a leaf in the tree. If the address points to another directory table, then that table lists directory entries at the next level down.

    A leaf's Type, Name, and Language IDs are determined by the path that is taken through directory tables to reach the leaf. The first table determines Type ID, the second table (pointed to by the directory entry in the first table) determines Name ID, and the third table determines Language ID.
    */
    var data: Data
    var rootDirectoryTable: ResourceDirectoryTable

    init(data: Data, sectionTable: SectionTable) throws {
        guard let resourceSection = sectionTable.sections.first(where: { $0.name.starts(with: ".rsrc") }) else {
            throw ResourceError.noResourceSection
        }
        self.data = data.subdata(in: Data.Index(resourceSection.pointerToRawData)..<Data.Index(resourceSection.pointerToRawData + resourceSection.sizeOfRawData))
        self.rootDirectoryTable = ResourceDirectoryTable(data: self.data,
                                                         offset: 0,
                                                         name: "root",
                                                         sectionTable: sectionTable)
    }
}
// swiftlint:enable line_length

struct ResourceError: Error {
    var message: String

    static let invalidResourceFile = ResourceError(message: "Invalid Resource file")
    static let noResourceSection = ResourceError(message: "No Resource section")
}

enum ResourceTypes: UInt32 {
    case cursor = 1
    case bitmap = 2
    case icon = 3
    case menu = 4
    case dialog = 5
    case string = 6
    case fontDir = 7
    case font = 8
    case accelerator = 9
    case rcData = 10
    case messageTable = 11
}
