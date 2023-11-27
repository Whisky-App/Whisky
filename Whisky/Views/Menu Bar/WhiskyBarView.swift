//
//  WhiskyBarView.swift
//  Whisky
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

import SwiftUI

/// Application wide menu for the menu bar
struct WhiskyBarView: View {
    @ObservedObject private var bottleVM = BottleVM.shared

    var body: some View {
        Button("kill.bottles", systemImage: "stop.circle.fill") {
            WhiskyApp.killBottles()
        }.labelStyle(.titleAndIcon)

        Section("menubar.bottles") {
            ForEach(bottleVM.bottles) { bottle in
                Menu(bottle.settings.name) {
                    BottleBarView(bottle: bottle)
                }
            }
        }.labelStyle(.titleAndIcon)
    }
}
