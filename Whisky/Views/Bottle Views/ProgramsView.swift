//
//  ProgramsView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct ProgramsView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Text("program.title")
                Spacer()
                Button(action: {
                    bottle.updateInstalledPrograms()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                })
                .buttonStyle(.bordered)
            }
            List {
                ForEach(bottle.programs, id: \.self) { program in
                    HStack {
                        Text(program.lastPathComponent)
                        Spacer()
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
            .cornerRadius(5)
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .onAppear {
                bottle.updateInstalledPrograms()
            }
        }
        .padding()
        .navigationTitle("\(bottle.name) \(NSLocalizedString("tab.programs", comment: ""))")
    }
}

struct ProgramsView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramsView(bottle: Bottle())
    }
}
