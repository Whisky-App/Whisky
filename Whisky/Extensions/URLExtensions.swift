//
//  URLExtensions.swift
//  Whisky
//
//  Created by Isaac Marovitz on 13/06/2023.
//

import Foundation

extension URL {
    func prettyPath() -> String {
        var prettyPath = path
        prettyPath = prettyPath
            .replacingOccurrences(of: "com.isaacmarovitz.Whisky", with: "Whisky")
            .replacingOccurrences(of: "/Users/\(NSUserName())", with: "~")
        return prettyPath
    }
}
