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

public enum INIValue: Hashable {
    case string(String)
    case dword(UInt32)
    case qword(UInt64)
    case hex([[UInt8]])
}

public typealias INIConfig = [String: [String: INIValue]]


extension String {
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}


private func parseKVP(content: String) -> (key: String, value: INIValue) {
    if content.first! == "@" {
        return (key: "@", value: INIValue.string(content.slice(from: "\"", to: "\"") ?? ""))
    }
    
    var kvp = (key: content.slice(from: "\"", to: "\"")!, value: INIValue.string(""))
    let rawValue = String(content.dropFirst(kvp.key.count + 3))
    switch (rawValue.first) {
        

    //dword:
    case "d":
        if !rawValue.hasPrefix("dword:") { break }
        kvp.value = INIValue.dword(UInt32(rawValue.dropFirst("dword:".count), radix: 16)!)
        break
        
    //qword:
    case "q":
        if !rawValue.hasPrefix("qword:") { break }
        kvp.value = INIValue.qword(UInt64(rawValue.dropFirst("qword:".count), radix: 16)!)
        break
        
    //hex:
    case "h":
        if !rawValue.hasPrefix("hex:") { break }
        let csv = rawValue.dropFirst("hex:".count)
        
        var val: [[UInt8]] = []
        for section in csv.components(separatedBy: " ") {
            var arr: [UInt8] = []
            for val in section.components(separatedBy: ",") {
                if val == "" { continue }
                arr.append(UInt8(val, radix: 16)!)
            }
            val.append(arr)
        }
        
        kvp.value = INIValue.hex(val)
        break
        
    case "\"": fallthrough
    default:
        kvp.value = INIValue.string(rawValue.slice(from: "\"", to: "\"") ?? "")
        
    }
    
    return kvp
}

private func parseSectionHeader(content: String) -> String {
    return content.slice(from: "[", to: "]")!
}

public func parseINI(_ iniContent: String) -> INIConfig {
    var cfg = INIConfig()
    
    //Change all \<NEWLINE> into one line, so the parser works
    let iniContent = iniContent.replacingOccurrences(of: "\\\n", with: "")
    
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
    return parseINI(try String(contentsOf: file))
}
