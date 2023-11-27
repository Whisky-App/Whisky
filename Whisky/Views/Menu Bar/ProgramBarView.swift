//
//  ProgramBarView.swift
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

/// A menu for a specific program
struct ProgramBarView: View {
    @ObservedObject var program: Program
    let pin: PinnedProgram?
    @State private var image: Image?

    var body: some View {
        Menu {
            ProgramMenuView(program: program)
        } label: {
            HStack {
                image
                Text(pin?.name ?? program.name)
            }
        } primaryAction: {
            Task {
                await program.run()
            }
        }
        .labelStyle(.titleAndIcon)
        .onAppear {
            guard pin != nil else { return }
            Task {
                image = await program.loadIcon()
            }
        }
    }
}

extension Program {
    var viewImage: Image? {
        guard let peFile = peFile else { return nil }
        guard let nsImage = peFile.bestIcon() else { return nil }
        return Image(nsImage: nsImage)
    }
}
