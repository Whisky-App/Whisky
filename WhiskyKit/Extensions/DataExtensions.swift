//
//  DataExtensions.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation

extension Data {
    public func extract<T>(_ type: T.Type, offset: Int = 0) -> T? {
        if offset + MemoryLayout<T>.size < self.count {
            let data = self[offset..<offset + MemoryLayout<T>.size]
            return data.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
        } else {
            return nil
        }
    }

    // Thanks ChatGPT
    public func nullTerminatedStrings(using encoding: String.Encoding = .utf8) -> [String] {
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
