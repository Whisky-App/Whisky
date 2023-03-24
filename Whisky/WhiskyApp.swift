//
//  WhiskyApp.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

@main
struct WhiskyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(selected: BottleVM.shared.bottles[0])
                .environmentObject(BottleVM.shared)
        }
    }
}
