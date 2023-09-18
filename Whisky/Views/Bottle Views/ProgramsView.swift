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
    // We don't actually care about the value
    // This just provides a way to trigger a refresh
    @State var resortPrograms: Bool = false
    @State var isExpanded: Bool = true
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
        }
        .formStyle(.grouped)
        .navigationTitle("tab.programs")
        .onAppear {
            programs = bottle.updateInstalledPrograms()
            sortPrograms()
        }
        .onChange(of: resortPrograms) {
            reloadStartMenu.toggle()
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
    }
}
