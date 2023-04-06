//
//  ResourceSection.swift
//  Whisky
//

import Foundation
import AppKit

struct ResourceDirectoryEntry: Hashable {
    var id: UInt32
    var offsetToData: UInt32
    var offsetToSubdirectory: UInt32
    var dataIsDirectory: Bool

    init(data: Data, offset: Int) {
        var offset = offset
        // Can be name or ID
        self.id = data.extract(UInt32.self, offset: offset)
        offset += 4
        self.offsetToData = data.extract(UInt32.self, offset: offset)
        offset += 4

        self.dataIsDirectory = (offsetToData & 0x80000000) != 0
        self.offsetToSubdirectory = offsetToData & 0x7FFFFFFF
    }
}

struct ResourceDataEntry: Hashable {
    var dataRVA: UInt32
    var size: UInt32
    var codePage: UInt32
    var reserved: UInt32
    var icon: NSImage = NSImage()

    init(data: Data, offset: Int, sectionTable: SectionTable) {
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
            let iconData = data.subdata(in: Int(offsetToData)..<Int(offsetToData + size))
            if let rep = NSBitmapImageRep(data: iconData) {
                icon = NSImage(size: rep.size)
                icon.addRepresentation(rep)
            }
        } else {
            print("Failed to resolve RVA")
        }
    }

    func resolveRVA (data: Data, rva: UInt32, sectionTable: SectionTable) -> UInt32? {
        for section in sectionTable.sections {
            if section.virtualAddress <= rva && rva < (section.virtualAddress + section.virtualSize) {
                let virtualAddress = section.pointerToRawData + (rva - section.virtualAddress)
                return virtualAddress
            }
        }

        return nil
    }
}

struct ResourceDirectoryTable: Hashable {
    var characteristics: UInt32
    var timeDateStamp: UInt32
    var majorVersion: UInt16
    var minorVersion: UInt16
    var numberOfNamedEntries: UInt16
    var numberOfIdEntries: UInt16

    var subtables: [ResourceDirectoryTable]
    var entries: [ResourceDataEntry]

    init(data: Data,
         address: Int,
         offset: Int,
         sectionTable: SectionTable,
         entries: inout [ResourceDataEntry],
         depth: Int = 0) {
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
            if depth == 0 && numberOfNamedEntriesIterated < numberOfNamedEntries {
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
                if depth == 0 {
                    if ResourceTypes(rawValue: entry.id) == .icon {
                        self.subtables.append(ResourceDirectoryTable(data: data,
                                                                     address: address,
                                                                     offset: Int(entry.offsetToSubdirectory) + address,
                                                                     sectionTable: sectionTable,
                                                                     entries: &entries,
                                                                     depth: depth + 1))
                    }
                } else {
                    self.subtables.append(ResourceDirectoryTable(data: data,
                                                                 address: address,
                                                                 offset: Int(entry.offsetToSubdirectory) + address,
                                                                 sectionTable: sectionTable,
                                                                 entries: &entries,
                                                                 depth: depth + 1))
                }
            } else {
                let entry = ResourceDataEntry(data: data,
                                              offset: Int(entry.offsetToData) + address,
                                              sectionTable: sectionTable)
                self.entries.append(entry)
                entries.append(entry)
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
    var rootDirectoryTable: ResourceDirectoryTable
    var allEntries: [ResourceDataEntry] = []

    init(data: Data, sectionTable: SectionTable, imageBase: UInt32) throws {
        guard let resourceSection = sectionTable.sections.first(where: { $0.name.starts(with: ".rsrc") }) else {
            throw ResourceError.noResourceSection
        }
        self.rootDirectoryTable = ResourceDirectoryTable(data: data,
                                                         address: Int(resourceSection.pointerToRawData),
                                                         offset: Int(resourceSection.pointerToRawData),
                                                         sectionTable: sectionTable,
                                                         entries: &allEntries)
    }
}
// swiftlint:enable line_length

struct ResourceError: Error {
    var message: String

    static let invalidResourceFile = ResourceError(message: "Invalid Resource file")
    static let noResourceSection = ResourceError(message: "No Resource section")
}

enum ResourceTypes: UInt32 {
    case icon = 3
}
