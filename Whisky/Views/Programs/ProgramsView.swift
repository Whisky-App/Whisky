//
//  ProgramsView.swift
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

struct ProgramsView: View {
    let bottle: Bottle
    @State var programs: [Program] = []
    @State var blocklist: [URL] = []
    @State private var selectedPrograms = Set<Program>()
    @State private var selectedBlockitems = Set<URL>()
    // We don't actually care about the value
    // This just provides a way to trigger a refresh
    @State var resortPrograms: Bool = false
    @State var isExpanded: Bool = true
    @State var isBlocklistExpanded: Bool = false
    @Binding var reloadStartMenu: Bool
    @Binding var path: NavigationPath

    var body: some View {
        Form {
            Section("program.title", isExpanded: $isExpanded) {
                List($programs, id: \.self, selection: $selectedPrograms) { $program in
                    ProgramItemView(program: program,
                                    resortPrograms: $resortPrograms,
                                    path: $path)
                }
                .contextMenu {
                    Button("program.add.blocklist") {
                        bottle.settings.blocklist.append(contentsOf: selectedPrograms.map { $0.url })
                        resortPrograms.toggle()
                    }
                }
            }
            Section("program.blocklist", isExpanded: $isBlocklistExpanded) {
                List($blocklist, id: \.self, selection: $selectedBlockitems) { $blockedUrl in
                    BlocklistItemView(blockedUrl: blockedUrl,
                                      bottle: bottle,
                                      resortPrograms: $resortPrograms)
                }
                .contextMenu {
                    Button("program.remove.blocklist") {
                        bottle.settings.blocklist.removeAll(where: { selectedBlockitems.contains($0) })
                        resortPrograms.toggle()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .animation(.easeInOut(duration: 0.2), value: programs)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .animation(.easeInOut(duration: 0.2), value: isBlocklistExpanded)
        .navigationTitle("tab.programs")
        .onAppear {
            programs = bottle.updateInstalledPrograms()
            blocklist = bottle.settings.blocklist
            sortPrograms()
        }
        .onChange(of: resortPrograms) {
            reloadStartMenu.toggle()
            programs = bottle.updateInstalledPrograms()
            blocklist = bottle.settings.blocklist
            sortPrograms()
        }
    }

    func sortPrograms() {
        var favourites = programs.filter { $0.pinned }
        var nonFavourites = programs.filter { !$0.pinned }
        favourites = favourites.sorted { $0.name < $1.name }
        nonFavourites = nonFavourites.sorted { $0.name < $1.name }
        programs.removeAll()
        programs.append(contentsOf: favourites)
        programs.append(contentsOf: nonFavourites)
    }
}

struct ProgramItemView: View {
    let program: Program
    @State var showButtons: Bool = false
    @State var isPinned: Bool = false
    @State var pinHovered: Bool = false
    @Binding var resortPrograms: Bool
    @Binding var path: NavigationPath

    var body: some View {
        HStack {
            Button {
                isPinned = program.togglePinned()
                resortPrograms.toggle()
            } label: {
                Image(systemName: isPinned ? pinHovered ? "pin.slash.fill" : "pin.fill" : "pin")
                    .onHover { hover in
                        pinHovered = hover
                    }
            }
            .buttonStyle(.plain)
            .foregroundColor(isPinned ? .accentColor : .secondary)
            .opacity(isPinned ? 1 : showButtons ? 1 : 0)
            Text(program.name)
            Spacer()
            if showButtons {
                if let peFile = program.peFile,
                   let archString = peFile.architecture.toString() {
                    Text(archString)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.secondary)
                        )
                }
                Button {
                    path.append(program)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("program.config")
                Button {
                    Task {
                        await program.run()
                    }
                } label: {
                    Image(systemName: "play")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("button.run")
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
        .onAppear {
            isPinned = program.pinned
        }
    }
}

struct BlocklistItemView: View {
    let blockedUrl: URL
    let bottle: Bottle
    @State var showButtons: Bool = false
    @Binding var resortPrograms: Bool

    var body: some View {
        HStack {
            Text(blockedUrl.prettyPath(bottle))
            Spacer()
            if showButtons {
                Button {
                    bottle.settings.blocklist.removeAll { $0 == blockedUrl }
                    resortPrograms.toggle()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("program.remove.blocklist")
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
    }
}
