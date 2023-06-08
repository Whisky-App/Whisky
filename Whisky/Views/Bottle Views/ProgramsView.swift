//
//  ProgramsView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ProgramsView: View {
    @State var bottle: Bottle
    @State var programs: [Program] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("program.title") {
                    List($programs, id: \.self) { program in
                        NavigationLink {
                            ProgramView(program: program)
                        } label: {
                            ProgramItemView(bottle: bottle, program: program)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(format: NSLocalizedString("tab.navTitle.programs",
                                                              comment: ""),
                                    bottle.name))
            .onAppear {
                programs = bottle.updateInstalledPrograms()
            }
        }
    }
}

struct ProgramItemView: View {
    @State var bottle: Bottle
    @Binding var program: Program
    @State var showButtons: Bool = false

    @State private var showAlert = false

    var body: some View {
        HStack {
            Text(program.name)
            Spacer()
            if showButtons {
                Button {
                    Task(priority: .userInitiated) {
                        do {
                            try await Wine.runProgram(program: program)
                        } catch {
                            showAlert = true
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
        .alert(
            "alert.message",
            isPresented: $showAlert,
            actions: { /* Blank, as we get an OK button for free */ },
            message: { Text("alert.info \(program.name)") }
        )
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramsView(bottle: Bottle())
    }
}
