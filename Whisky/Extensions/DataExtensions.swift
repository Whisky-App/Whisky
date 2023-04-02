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
        return data.withUnsafeBytes { $0.load(as: T.self) }
    }
}
