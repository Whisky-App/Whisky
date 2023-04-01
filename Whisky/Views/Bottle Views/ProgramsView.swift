//
//  ProgramsView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ProgramsView: View {
    @State var bottle: Bottle
    @State var programs: [URL] = []

    var body: some View {
        Form {
            Section("program.title") {
                List {
                    ForEach(programs, id: \.self) { program in
                        ProgramItemView(bottle: bottle, program: program)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("\(bottle.name) \(NSLocalizedString("tab.programs", comment: ""))")
        .onAppear {
            programs = bottle.updateInstalledPrograms()
        }
    }
}

struct ProgramItemView: View {
    @State var bottle: Bottle
    @State var program: URL
    @State var showButtons: Bool = false

    var body: some View {
        HStack {
            Text(program.lastPathComponent)
            Spacer()
            if showButtons {
                Group {
                    Button(action: {
                    }, label: {
                        Image(systemName: "ellipsis.circle.fill")
                    })
                    .buttonStyle(.plain)
                    Button(action: {
                        Task(priority: .userInitiated) {
                            do {
                                try await Wine.runProgram(bottle: bottle,
                                                          path: program.path)
                            } catch {
                                let alert = NSAlert()
                                alert.messageText = "alert.message"
                                alert.informativeText = "alert.info" + " \(program.lastPathComponent)"
                                alert.alertStyle = .critical
                                alert.addButton(withTitle: "button.ok")
                                alert.runModal()
                            }
                        }
                    }, label: {
                        Image(systemName: "play.circle.fill")
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(4)
        .onHover { hover in
            showButtons = hover
        }
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramsView(bottle: Bottle())
    }
}
