//
//  WhiskyApp.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

@main
struct WhiskyApp: App {
    let bottles = [
        Bottle("Test"),
        Bottle("Steam"),
        Bottle("Genshin Impact")
    ]

    var body: some Scene {
        WindowGroup {
            ContentView(bottles: bottles, selected: bottles[0])
        }
    }
}
