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

    var body: some View {
        NavigationStack {
            Form {
                Section("program.title", isExpanded: $isExpanded) {
                    List($programs, id: \.self) { $program in
                        NavigationLink {
                            ProgramView(program: $program)
                        } label: {
                            ProgramItemView(program: program, resortPrograms: $resortPrograms)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(format: String(localized: "tab.navTitle.programs"),
                                    bottle.settings.name))
            .onAppear {
                programs = bottle.updateInstalledPrograms()
                sortPrograms()
            }
            .onChange(of: resortPrograms) {
                reloadStartMenu.toggle()
                sortPrograms()
            }
        }
    }

    func sortPrograms() {
        var favourites = programs.filter { $0.favourited }
        var nonFavourites = programs.filter { !$0.favourited }
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
    @State var isFavourited: Bool = false
    @Binding var resortPrograms: Bool

    var body: some View {
        HStack {
            Button {
                isFavourited = program.toggleFavourited()
                resortPrograms.toggle()
            } label: {
                Image(systemName: isFavourited ? "star.fill" : "star")
            }
            .buttonStyle(.plain)
            .foregroundColor(isFavourited ? .accentColor : .secondary)
            .opacity(isFavourited ? 1 : showButtons ? 1 : 0)
            Text(program.name)
            Spacer()
            if showButtons {
                if let peFile = program.peFile,
                   let archString = peFile.architecture.toString() {
                    Text(archString)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.secondary)
                        )
                }
                Button {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.runProgram(program: program)
                        } catch {
                            let alert = NSAlert()
                            alert.messageText = String(localized: "alert.message")
                            alert.informativeText = String(localized: "alert.info") + " \(program.name)"
                            alert.alertStyle = .critical
                            alert.addButton(withTitle: String(localized: "button.ok"))
                            alert.runModal()
                        }
                    }
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
            isFavourited = program.favourited
        }
    }
}
