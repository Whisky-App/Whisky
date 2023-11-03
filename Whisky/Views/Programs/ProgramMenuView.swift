//
//  ProgramMenuView.swift
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
import WhiskyKit

struct ProgramMenuView: View {
    @ObservedObject var program: Program
    @Binding var path: NavigationPath

    var body: some View {
        Button("button.run", systemImage: "play") {
            Task {
                await program.run()
            }
        }
        .labelStyle(.titleAndIcon)
        Section("program.settings") {
            Button("program.config", systemImage: "gearshape") {
                path.append(program)
            }
            .labelStyle(.titleAndIcon)

            let buttonName = program.pinned
            ? String(localized: "button.unpin")
            : String(localized: "button.pin")

            let iconName = program.pinned ? "pin.slash" : "pin"
            Button(buttonName, systemImage: iconName) {
                program.pinned.toggle()
            }
            .labelStyle(.titleAndIcon)
        }
    }
}
