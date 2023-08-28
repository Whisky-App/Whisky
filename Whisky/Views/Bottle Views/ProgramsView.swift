//
//  ProgramsView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ProgramsView: View {
    let bottle: Bottle
    @State var programs: [Program] = []
    // We don't actually care about the value
    // This just provides a way to trigger a refresh
    @State var resortPrograms: Bool = false
    @Binding var reloadStartMenu: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("program.title") {
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
            .foregroundColor(isFavourited ? .yellow : .primary)
            .opacity(isFavourited ? 1 : showButtons ? 1 : 0)
            Text(program.name)
            Spacer()
            if showButtons {
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
                    Image(systemName: "play.circle.fill")
                }
                .buttonStyle(.plain)
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

struct ProgramsView_Previews: PreviewProvider {
    @State private static var reloadStartMenu: Bool = false
    static var previews: some View {
        ProgramsView(bottle: Bottle(), reloadStartMenu: $reloadStartMenu)
    }
}
