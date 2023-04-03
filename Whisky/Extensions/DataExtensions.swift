//
//  DataExtensions.swift
//  Whisky
//
//  Created by Isaac Marovitz on 01/04/2023.
//

import Foundation

extension Data {
    func extract<T>(_ type: T.Type, offset: Int = 0) -> T {
        let data = self[offset..<offset + MemoryLayout<T>.size]
        return data.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
    }

    // Thanks ChatGPT
    func nullTerminatedStrings(using encoding: String.Encoding = .utf8) -> [String] {
        var strings = [String]()
        self.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            if let baseAddress = ptr.baseAddress {
                var strStart = baseAddress
                let strEnd = baseAddress + self.count
                while strStart < strEnd {
                    let strPtr = strStart.assumingMemoryBound(to: CChar.self)
                    let strLen = strnlen(strPtr, self.count)
                    let strData = Data(bytes: strPtr, count: strLen)
                    if let str = String(data: strData, encoding: encoding) {
                        strings.append(str)
                    }
                    strStart = strStart.advanced(by: strLen + 1)
                }
            }
        }
        return strings
    }
}
