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
    @ObservedObject var bottle: Bottle
    @State private var blocklist: [URL] = []
    @State private var selectedPrograms = Set<Program>()
    @State private var selectedBlockitems = Set<URL>()
    @Binding var path: NavigationPath
    @State private var sortedPrograms: [Program] = []
    @State private var resortPrograms = false
    @State private var searchText = ""

    @AppStorage("areProgramsExpanded") private var areProgramsExpanded = true
    @AppStorage("isBlocklistExpanded") private var isBlocklistExpanded = false

    private var searchResults: [Program] {
        guard !searchText.isEmpty else { return sortedPrograms }
        return sortedPrograms.filter({ $0.name.localizedCaseInsensitiveContains(searchText) })
    }

    private var searchedBlocklists: [URL] {
        guard !searchText.isEmpty else { return blocklist }
        return blocklist.filter({ $0.absoluteString.localizedCaseInsensitiveContains(searchText) })
    }

    private var selectedSearchedPrograms: [Program] {
        searchResults.filter({ selectedPrograms.contains($0) })
    }

    var body: some View {
        Form {
            Section("program.title", isExpanded: $areProgramsExpanded) {
                List(searchResults, id: \.self, selection: $selectedPrograms) { program in
                    ProgramItemView(
                        bottle: bottle, program: program, path: $path
                    )
                    .contextMenu {
                        let selectedPrograms = selectedSearchedPrograms
                        if selectedPrograms.contains(program) && selectedPrograms.count > 1 {
                            Button("program.add.selected.blocklist", systemImage: "hand.raised") {
                                bottle.settings.blocklist.append(contentsOf: selectedPrograms.map { $0.url })
                                blocklist = bottle.settings.blocklist
                            }
                            .labelStyle(.titleAndIcon)
                        } else {
                            ProgramMenuView(program: program, path: $path)

                            Section {
                                Button("program.add.blocklist", systemImage: "hand.raised") {
                                    bottle.settings.blocklist.append(program.url)
                                    blocklist = bottle.settings.blocklist
                                }
                                .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                }
            }
            .animation(.whiskyDefault, value: sortedPrograms)

            Section("program.blocklist", isExpanded: $isBlocklistExpanded) {
                List(searchedBlocklists, id: \.self, selection: $selectedBlockitems) { blockedUrl in
                    BlocklistItemView(
                        blockedUrl: blockedUrl, bottle: bottle
                    )
                    .contextMenu {
                        if selectedBlockitems.contains(blockedUrl) {
                            Button("program.remove.selected.blocklist", systemImage: "hand.raised") {
                                bottle.settings.blocklist.removeAll(where: { selectedBlockitems.contains($0) })
                                blocklist = bottle.settings.blocklist
                            }
                            .labelStyle(.titleAndIcon)
                            .symbolVariant(.slash)
                        } else {
                            Button("program.remove.blocklist", systemImage: "hand.raised") {
                                bottle.settings.blocklist.removeAll(where: { $0 == blockedUrl })
                                blocklist = bottle.settings.blocklist
                            }
                            .labelStyle(.titleAndIcon)
                            .symbolVariant(.slash)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .animation(.whiskyDefault, value: sortedPrograms)
        .animation(.whiskyDefault, value: bottle.settings.blocklist)
        .animation(.whiskyDefault, value: searchText)
        .animation(.whiskyDefault, value: areProgramsExpanded)
        .animation(.whiskyDefault, value: isBlocklistExpanded)
        .navigationTitle("tab.programs")
        .searchable(text: $searchText)
        .onAppear {
            loadData()
        }
        .onChange(of: resortPrograms) {
            loadPrograms()
        }
        .onChange(of: bottle.settings) {
            loadData()
        }
    }

    private func loadData() {
        loadPrograms()
        blocklist = bottle.settings.blocklist.filter({
            return FileManager.default.fileExists(atPath: $0.path(percentEncoded: false))
        })
    }

    private func loadPrograms() {
        let programs = bottle.programs.filter({
            return FileManager.default.fileExists(atPath: $0.url.path(percentEncoded: false))
        })
        sortedPrograms = [
            programs.pinned.sorted { $0.name < $1.name },
            programs.unpinned.sorted { $0.name < $1.name }
        ].flatMap { $0 }
    }
}

struct ProgramItemView: View {
    @ObservedObject var bottle: Bottle
    @ObservedObject var program: Program
    @Binding var path: NavigationPath
    @State private var showButtons = false
    @State private var pinHovered = false

    var body: some View {
        HStack {
            Button {
                program.pinned.toggle()
            } label: {
                Image(systemName: "pin")
                    .onHover { hover in
                        pinHovered = hover
                    }
                    .symbolVariant(program.pinned ? pinHovered ? .slash.fill : .fill : .none)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .foregroundColor(program.pinned ? .accentColor : .secondary)
            .opacity(program.pinned ? 1 : showButtons ? 1 : 0)
            Text(program.name)
                .frame(maxWidth: .infinity, alignment: .leading)
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

                Button("program.config", systemImage: "gearshape") {
                    path.append(program)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("program.config")
                Button("button.run", systemImage: "play") {
                    program.run()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("button.run")
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
    }
}

struct BlocklistItemView: View {
    let blockedUrl: URL
    @ObservedObject var bottle: Bottle
    @State private var showButtons: Bool = false

    var body: some View {
        HStack {
            Text(blockedUrl.prettyPath(bottle))
            Spacer()
            if showButtons {
                Button("program.remove.blocklist", systemImage: "xmark") {
                    bottle.settings.blocklist.removeAll { $0 == blockedUrl }
                }
                .labelStyle(.iconOnly)
                .symbolVariant(.fill.circle)
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
