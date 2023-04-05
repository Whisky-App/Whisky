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
    @State var startMenuPrograms: [ShellLinkHeader] = []

    @State private var gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: gridLayout, alignment: .center) {
                    ForEach(startMenuPrograms, id: \.self) { program in
                        NavigationLink {
                            EmptyView()
                        } label: {
                            ShellLinkView(program: program)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .onAppear {
                    startMenuPrograms = bottle.updateStartMenuPrograms()
                }
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
                }
            }
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
                            } else {
                                programLoading = false
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

struct ShellLinkView: View {
    @State var program: ShellLinkHeader
    @State var image: NSImage?

    var body: some View {
        VStack {
            if let stringData = program.stringData, let icon = stringData.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 45, height: 45)
            } else {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 45, height: 45)
                } else {
                    Image(systemName: "app.dashed")
                        .resizable()
                        .frame(width: 45, height: 45)
                }
            }
            Spacer()
            Text(program.url
                .deletingPathExtension()
                .lastPathComponent)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .onAppear {
            if let linkInfo = program.linkInfo, let url = linkInfo.linkDestination {
                image = NSWorkspace.shared.icon(forFile: url.path)
                do {
                    print(url.lastPathComponent)
                    _ = try COFFFileHeader(data: Data(contentsOf: url))
                } catch {
                    print(error)
                }
            }
        }
    }
}
