//
//  ResourceSection.swift
//  Whisky
//

import Foundation
import AppKit

public struct ResourceDirectoryEntry: Hashable {
    public let id: UInt32
    public let offsetToData: UInt32
    public let offsetToSubdirectory: UInt32
    public let dataIsDirectory: Bool

    init(data: Data, offset: Int) {
        var offset = offset
        // Can be name or ID
        self.id = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.offsetToData = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        self.dataIsDirectory = (offsetToData & 0x80000000) != 0
        self.offsetToSubdirectory = offsetToData & 0x7FFFFFFF
    }
}

public struct ResourceDataEntry: Hashable {
    public let dataRVA: UInt32
    public let size: UInt32
    public let codePage: UInt32
    public let reserved: UInt32
    public let icon: NSImage

    init(data: Data, offset: Int, sectionTable: SectionTable) {
        var offset = offset
        var icon = NSImage()
        self.dataRVA = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.size = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.codePage = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.reserved = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4

        if let offsetToData = ResourceDataEntry.resolveRVA(data: data, rva: dataRVA, sectionTable: sectionTable) {
            let bitmapInfo = BitmapInfoHeader(data: data, offset: Int(offsetToData))
            if bitmapInfo.size != 40 {
                let iconData = data.subdata(in: Int(offsetToData)..<Int(offsetToData + size))
                if let rep = NSBitmapImageRep(data: iconData) {
                    icon = NSImage(size: rep.size)
                    icon.addRepresentation(rep)
                }
            } else {
                if bitmapInfo.colorFormat != .unknown {
                    icon = bitmapInfo.renderBitmap(data: data,
                                                   offset: Int(offsetToData + bitmapInfo.size))
                }
            }
        } else {
            print("Failed to resolve RVA")
        }

        self.icon = icon
    }

    static func resolveRVA (data: Data, rva: UInt32, sectionTable: SectionTable) -> UInt32? {
        for section in sectionTable.sections {
            if section.virtualAddress <= rva && rva < (section.virtualAddress + section.virtualSize) {
                let virtualAddress = section.pointerToRawData + (rva - section.virtualAddress)
                return virtualAddress
            }
        }

        return nil
    }
}

public struct ResourceDirectoryTable: Hashable {
    public let characteristics: UInt32
    public let timeDateStamp: UInt32
    public let majorVersion: UInt16
    public let minorVersion: UInt16
    public let numberOfNamedEntries: UInt16
    public let numberOfIdEntries: UInt16

    public let subtables: [ResourceDirectoryTable]
    public let entries: [ResourceDataEntry]

    init(data: Data,
         address: Int,
         offset: Int,
         sectionTable: SectionTable,
         entries: inout [ResourceDataEntry],
         depth: Int = 0) {
        var offset = offset
        self.characteristics = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.timeDateStamp = data.extract(UInt32.self, offset: offset) ?? 0
        offset += 4
        self.majorVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.minorVersion = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.numberOfNamedEntries = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2
        self.numberOfIdEntries = data.extract(UInt16.self, offset: offset) ?? 0
        offset += 2

        var subtables: [ResourceDirectoryTable] = []

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
                        subtables.append(ResourceDirectoryTable(data: data,
                                                                     address: address,
                                                                     offset: Int(entry.offsetToSubdirectory) + address,
                                                                     sectionTable: sectionTable,
                                                                     entries: &entries,
                                                                     depth: depth + 1))
                    }
                } else {
                    subtables.append(ResourceDirectoryTable(data: data,
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
                entries.append(entry)
            }
        }

        self.subtables = subtables
        self.entries = entries
    }
}

// swiftlint:disable line_length
public struct ResourceSection: Hashable {
    /*
    Resources are indexed by a multiple-level binary-sorted tree structure. The general design can incorporate 2**31 levels. By convention, however, Windows uses three levels:

    Type Name Language
    A series of resource directory tables relates all of the levels in the following way: Each directory table is followed by a series of directory entries that give the name or identifier (ID) for that level (Type, Name, or Language level) and an address of either a data description or another directory table. If the address points to a data description, then the data is a leaf in the tree. If the address points to another directory table, then that table lists directory entries at the next level down.

    A leaf's Type, Name, and Language IDs are determined by the path that is taken through directory tables to reach the leaf. The first table determines Type ID, the second table (pointed to by the directory entry in the first table) determines Name ID, and the third table determines Language ID.
    */
    public let rootDirectoryTable: ResourceDirectoryTable
    public let allEntries: [ResourceDataEntry]

    init(data: Data, sectionTable: SectionTable, imageBase: UInt32) throws {
        guard let resourceSection = sectionTable.sections.first(where: { $0.name.starts(with: ".rsrc") }) else {
            throw ResourceError.noResourceSection
        }
        var entries: [ResourceDataEntry] = []
        self.rootDirectoryTable = ResourceDirectoryTable(data: data,
                                                         address: Int(resourceSection.pointerToRawData),
                                                         offset: Int(resourceSection.pointerToRawData),
                                                         sectionTable: sectionTable,
                                                         entries: &entries)
        self.allEntries = entries
    }
}
// swiftlint:enable line_length

public struct ResourceError: Error {
    public let message: String

    static let invalidResourceFile = ResourceError(message: "Invalid Resource file")
    static let noResourceSection = ResourceError(message: "No Resource section")
}

public enum ResourceTypes: UInt32 {
    case icon = 3
}
