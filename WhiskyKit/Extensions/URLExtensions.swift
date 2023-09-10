//
//  URLExtensions.swift
//  WhiskyKit
//
//  Created by Isaac Marovitz on 13/06/2023.
//

import Foundation

extension String {
    public var esc: String {
        let esc = ["\\", "\"", "'", " ", "(", ")", "[", "]", "{", "}", "&", "|",
                   ";", "<", ">", "`", "$", "!", "*", "?", "#", "~", "="]
        var str = self
        for char in esc {
            str = str.replacingOccurrences(of: char, with: "\\" + char)
        }
        return str
    }
}

extension URL {
    public var esc: String {
        path.esc
    }

    public func prettyPath() -> String {
        var prettyPath = path
        prettyPath = prettyPath
            .replacingOccurrences(of: Bundle.main.bundleIdentifier ?? "com.isaacmarovitz.Whisky", with: "Whisky")
            .replacingOccurrences(of: "/Users/\(NSUserName())", with: "~")
        return prettyPath
    }
}
