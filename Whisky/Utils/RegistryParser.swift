//
//  Registry.swift
//  Whisky
//
//  Created by Amrit Bhogal on 07/06/2023.
//

import Foundation

public enum RegistryValue: Hashable {
    case string(String)
    case dword(UInt32)
    case qword(UInt64)
    case hex([[UInt8]])
}

public typealias RegistryConfig = [String: [String: RegistryValue]]

extension String {
    // swiftlint:disable:next identifier_name
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

// swiftlint:disable:next cyclomatic_complexity
private func parseKVP(content: String) -> (key: String, value: RegistryValue) {
    if content.first == "@" {
        return (key: "@", value: .string(content.slice(from: "\"", to: "\"") ?? ""))
    }

    var kvp = (key: content.slice(from: "\"", to: "\"")!, value: RegistryValue.string(""))
    let rawValue = String(content.dropFirst(kvp.key.count + 3))
    switch rawValue.first {
    // DWORD:
    case "d":
        guard rawValue.hasPrefix("dword:") else { break }
        if let val = UInt32(rawValue.dropFirst("dword:".count), radix: 16) {
            kvp.value = .dword(val)
        }

    // QWORD:
    case "q":
        guard rawValue.hasPrefix("qword:") else { break }
        if let val = UInt64(rawValue.dropFirst("qword:".count), radix: 16) {
            kvp.value = .qword(val)
        }

    // Hex:
    case "h":
        guard rawValue.hasPrefix("hex:") else { break }
        let csv = rawValue.dropFirst("hex:".count)

        var val: [[UInt8]] = []
        for section in csv.components(separatedBy: " ") {
            var arr: [UInt8] = []
            for val in section.components(separatedBy: ",") {
                guard val != "" else { continue }
                if let value = UInt8(val, radix: 16) {
                    arr.append(value)
                }
            }
            val.append(arr)
        }

        kvp.value = .hex(val)

    default:
        kvp.value = .string(rawValue.slice(from: "\"", to: "\"") ?? "")

    }

    return kvp
}

private func parseSectionHeader(content: String) -> String {
    return content.slice(from: "[", to: "]") ?? ""
}

public func parseRegistry(_ iniContent: String) -> RegistryConfig {
    var cfg = RegistryConfig()

    // Change all \<NEWLINE> into one line, so the parser works
    let iniContent = iniContent.replacingOccurrences(of: "\\\n", with: "")

    var latestSection = ""
    for line in iniContent.components(separatedBy: "\n") {
        switch line.first ?? ";" {
        case "[":
            latestSection = parseSectionHeader(content: line)
            cfg[latestSection] = [:]
        case "@":
            let kvp = parseKVP(content: line)
            cfg[latestSection]![kvp.key] = kvp.value

        default: break
        }
    }

    return cfg
}

public func parseRegistryFile(_ file: URL) throws -> RegistryConfig {
    return parseRegistry(try String(contentsOf: file))
}
