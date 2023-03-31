//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct BottleView: View {
    @Binding var bottle: Bottle
    @State var programLoading: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                NavigationLink {
                    ConfigView(bottle: $bottle)
                } label: {
                    Label("tab.config", systemImage: "gearshape.fill")
                }
                NavigationLink {
                    ProgramsView(bottle: bottle)
                } label: {
                    Label("tab.programs", systemImage: "macwindow")
                }
                NavigationLink {
                    InfoView(bottle: bottle)
                } label: {
                    Label("tab.info", systemImage: "info.circle.fill")
                }
            }
            .formStyle(.grouped)
            Spacer()
            HStack {
                Spacer()
                Button("button.cDrive") {
                    bottle.openCDrive()
                }
                Button("button.run") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.canChooseFiles = true
                    panel.allowedContentTypes = [UTType.exe,
                                                 UTType(importedAs: "com.microsoft.msi-installer")]
                    panel.begin { result in
                        programLoading = true
                        Task(priority: .userInitiated) {
                            if result == .OK {
                                if let url = panel.urls.first {
                                    do {
                                        try await Wine.runProgram(bottle: bottle, path: url.path)
                                        programLoading = false
                                    } catch {
                                        programLoading = false
                                        let alert = NSAlert()
                                        alert.messageText = "alert.message"
                                        alert.informativeText = "alert.info" + " \(url.lastPathComponent)"
                                        alert.alertStyle = .critical
                                        alert.addButton(withTitle: "button.ok")
                                        alert.runModal()
                                    }
                                }
                            }
                        }
                    }
                }
                .disabled(programLoading)
                if programLoading {
                    Spacer()
                        .frame(width: 10)
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding()
        }
        .navigationTitle(bottle.name)
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        BottleView(bottle: .constant(Bottle()))
            .frame(width: 500, height: 300)
    }
}
