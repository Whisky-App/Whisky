//
//  BottleBarView.swift
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

/// A menu for a single bottle
struct BottleBarView: View {
    @ObservedObject var bottle: Bottle

    var body: some View {
        Group {
            Button("button.run", systemImage: "play") {
                Task {
                    guard let fileURL = await bottle.choseFileForRun() else { return }

                    do {
                        try await bottle.openFileForRun(url: fileURL)
                    } catch {
                        Bottle.logger.error("Failed to run external program: \(error)")
                    }
                }
            }

            Section("tab.programs") {
                let pinnedPrograms = bottle.pinnedPrograms
                let unpinnedPrograms = bottle.programs.unpinned

                ForEach(pinnedPrograms, id: \.pin.url) { pinnedProgram in
                    ProgramBarView(program: pinnedProgram.program, pin: pinnedProgram.pin)
                }

                Menu("menubar.morePrograms") {
                    ForEach(unpinnedPrograms, id: \.url) { program in
                        ProgramBarView(program: program, pin: nil)
                    }
                }.badge(unpinnedPrograms.count)
            }
        }
    }
}

private extension Sequence where Iterator.Element == Program {
    /// Filter all pinned programs
    var pinned: [Program] {
        return self.filter({ $0.pinned })
    }

    /// Filter all unpinned programs
    var unpinned: [Program] {
        return self.filter({ !$0.pinned })
    }
}
