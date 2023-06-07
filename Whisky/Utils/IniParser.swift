//
//  IniParser.swift
//  Whisky
//
//  Created by Amrit Bhogal on 06/06/2023.
//
// Original: https://gist.github.com/jetmind/f776c0d223e4ac6aec1ff9389e874553
//

import Foundation

public typealias IniSectionConfig = [String : String]
public typealias IniConfig = [String : IniSectionConfig]


func trim(_ str: String) -> String {
    let whitespaces = CharacterSet(charactersIn: " \n\r\t")
    return str.trimmingCharacters(in: whitespaces)
}


func stripComment(_ line: String) -> String {
    let parts = line.split(
      separator: "#",
      maxSplits: 1,
      omittingEmptySubsequences: false)
    if parts.count > 0 {
        return String(parts[0])
    }
    return ""
}


func parseSectionHeader(_ line: String) -> String {
    let from = line.index(after: line.startIndex)
    let to = line.index(before: line.endIndex)
    return String(line[from..<to])
}


func parseLine(_ line: String) -> (String, String)? {
    let parts = stripComment(line).split(separator: "=", maxSplits: 1)
    if parts.count == 2 {
        let key = trim(String(parts[0]))
        let val = trim(String(parts[1]))
        return (key, val)
    }
    return nil
}


public func parseIniConfig(_ filename : URL) -> IniConfig {
    // swiftlint:disable all
    let file = try! String(contentsOf: filename)
    // swiftlint:enable all
    var config = IniConfig()
    var currentSectionName = "main"
    for line in file.components(separatedBy: "\n") {
        let line = trim(line)
        if line.hasPrefix("[") && line.hasSuffix("]") {
            currentSectionName = parseSectionHeader(line)
        } else if let (key, val) = parseLine(line) {
            var section = config[currentSectionName] ?? [:]
            section[key] = val
            config[currentSectionName] = section
        }
    }
    return config
}

