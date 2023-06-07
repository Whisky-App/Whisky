//
//  INIParser.swift
//  Whisky
//
//  Created by Amrit Bhogal on 07/06/2023.
//

/*
 WINE REGISTRY Version 2
 ;; All keys relative to \\Machine

 #arch=win64

 [Software\\Borland\\Database Engine\\Settings\\SYSTEM\\INIT] 1686110674
 #time=1d998f52b0fbce0
 "SHAREDMEMLOCATION"="9000"

 [Software\\Classes\\*\\shellex\\ContextMenuHandlers] 1686110674
 #time=1d998f52b0d64d6

 [Software\\Classes\\.ai] 1686110673
 #time=1d998f52ac12a4e
 "Content Type"="application/postscript"

 [Software\\Classes\\.avi] 1686110673
 #time=1d998f52ac026da
 "Content Type"="video/avi"

 [Software\\Classes\\.bmp] 1686110673
 #time=1d998f52ac02d2e
 "Content Type"="image/bmp"

 [Software\\Classes\\.chm] 1686110674
 #time=1d998f52b0d2a66
 @="chm.file"

 [Software\\Classes\\.cpl] 1686110674
 #time=1d998f52b0d3150
 @="cplfile"

 [Software\\Classes\\.css] 1686110673
 #time=1d998f52ac03012
 "Content Type"="text/css"

 [Software\\Classes\\.dib] 1686110673
 #time=1d998f52ac03184
 "Content Type"="image/bmp"

 [Software\\Classes\\.dll] 1686110673
 #time=1d998f52ac0347c
 @="dllfile"
 "Content Type"="application/x-msdownload"
*/

import Foundation

extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

public typealias INIConfig = [String: [String: String]]

private func parseKVP(content: String) -> (key: String, value: String) {
    if content.first! == "@" { return (key: "@", value: "") }
    
    var kvp = (key: content.slice(from: "\"", to: "\"")!, value: "")
    kvp.value = String(content.dropFirst(kvp.key.count + 3))
    
    return kvp
}

private func parseSectionHeader(content: String) -> String {
    return content.slice(from: "[", to: "]")!
}

public func parseINI(iniContent: String) -> INIConfig {
    var cfg = INIConfig()
    
    var latestSection = ""
    for line in iniContent.components(separatedBy: "\n") {
        switch line.first ?? ";" {
        case "[":
            latestSection = parseSectionHeader(content: line)
            cfg[latestSection] = [:]
            break
           
        case "\"": fallthrough
        case "@":
            let kvp = parseKVP(content: line)
            cfg[latestSection]![kvp.key] = kvp.value
            break
            
        default: break
        }
    }
    
    return cfg
}

public func parseINIFile(_ file: URL) throws -> INIConfig {
    return parseINI(iniContent: try String(contentsOf: file))
}

print("Parsing \(CommandLine.arguments[1])")
let ini = try parseINIFile(URL(fileURLWithPath: CommandLine.arguments[1]))

for (key, val) in ini {
    print("\(key)\t=\t\(val)")
}
