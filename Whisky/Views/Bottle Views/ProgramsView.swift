//
//  ProgramsView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI
import WhiskyKit

struct ProgramsView: View {
    let bottle: Bottle
    @State var programs: [Program] = []
    @State var blocklist: [URL] = []
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
                List($programs, id: \.self) { $program in
                    ProgramItemView(program: program,
                                    resortPrograms: $resortPrograms,
                                    path: $path)
                }
            }
            Section("program.blocklist", isExpanded: $isBlocklistExpanded) {
                List($blocklist, id: \.self) { $blockedUrl in
                    BlocklistItemView(blockedUrl: blockedUrl,
                                      bottle: bottle,
                                      resortPrograms: $resortPrograms)
                }
            }
        }
        .formStyle(.grouped)
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
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
        .onAppear {
            isPinned = program.pinned
        }
        .contextMenu {
            Button("program.add.blocklist") {
                program.bottle.settings.blocklist.append(program.url)
                resortPrograms.toggle()
            }
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
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
    }
}
