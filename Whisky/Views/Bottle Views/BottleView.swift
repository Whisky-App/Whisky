//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLookThumbnailing

struct BottleView: View {
    @Binding var bottle: Bottle
    @State var programLoading: Bool = false
    @State var startMenuPrograms: [ShellLinkHeader] = []
    @State var shortcuts: [Shortcut] = []
    // We don't actually care about the value
    // This just provides a way to trigger a refresh
    @State var loadStartMenu: Bool = false

    private let gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        VStack {
            ScrollView {
                if startMenuPrograms.count > 0  || shortcuts.count > 0 {
                    NavigationStack {
                        LazyVGrid(columns: gridLayout, alignment: .center) {
                            ForEach(startMenuPrograms, id: \.self) { link in
                                NavigationLink {
                                    if let link = link.linkInfo, let program = link.program {
                                        ProgramView(program: .constant(program))
                                    }
                                } label: {
                                    ShellLinkView(link: link, loadStartMenu: $loadStartMenu)
                                }
                                .buttonStyle(.plain)
                                .overlay {
                                    HStack {
                                        Spacer()
                                        Button {
                                            if let link = link.linkInfo, let program = link.program {
                                                Task {
                                                    await program.run()
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "play.fill")
                                                .resizable()
                                                .foregroundColor(.green)
                                                .frame(width: 16, height: 16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(width: 45, height: 45) // Same size as ShellLinkView's icon
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                }
                            }
                            ForEach(shortcuts, id: \.link) { shortcut in
                                NavigationLink {
                                    let program = Program(name: shortcut.name,
                                                          url: shortcut.link,
                                                          bottle: bottle)
                                    ProgramView(program: .constant(program))
                                } label: {
                                    ShortcutView(bottle: bottle,
                                                 shortcut: shortcut,
                                                 loadStartMenu: $loadStartMenu)
                                }
                                .buttonStyle(.plain)
                                .overlay {
                                    HStack {
                                        Spacer()
                                        Button {
                                            let program = Program(name: shortcut.name,
                                                                  url: shortcut.link,
                                                                  bottle: bottle)
                                            Task {
                                                await program.run()
                                            }
                                        } label: {
                                            Image(systemName: "play.fill")
                                                .resizable()
                                                .foregroundColor(.green)
                                                .frame(width: 16, height: 16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(width: 45, height: 45) // Same size as ShellLinkView's icon
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                }
                            }
                        }
                        .padding()
                    }
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
                    .onAppear {
                        updateStartMenu()
                    }
                    .onChange(of: loadStartMenu) { _ in
                        updateStartMenu()
                    }
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
                    panel.directoryURL = bottle.url
                    panel.begin { result in
                        programLoading = true
                        Task(priority: .userInitiated) {
                            if result == .OK {
                                if let url = panel.urls.first {
                                    do {
                                        try await Wine.runExternalProgram(url: url, bottle: bottle)
                                    } catch {
                                        print("Failed to run external program: \(error)")
                                    }
                                    programLoading = false
                                }
                            } else {
                                programLoading = false
                            }
                            updateStartMenu()
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
        .navigationTitle(bottle.settings.name)
    }

    func updateStartMenu() {
        startMenuPrograms = bottle.updateStartMenuPrograms()
        shortcuts = bottle.settings.shortcuts
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        BottleView(bottle: .constant(Bottle()))
            .frame(width: 500, height: 300)
    }
}

struct ShellLinkView: View {
    @State var link: ShellLinkHeader
    @State var image: NSImage?
    @Binding var loadStartMenu: Bool

    var body: some View {
        VStack {
            if let stringData = link.stringData, let icon = stringData.icon {
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
            Text(link.url
                .deletingPathExtension()
                .lastPathComponent + "\n")
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .contextMenu {
            Button("Delete Shortcut") {
                do {
                    try FileManager.default.removeItem(at: link.url)
                    loadStartMenu.toggle()
                } catch {
                    print("Failed to delete shortcut: \(error)")
                }
            }
        }
        .onAppear {
            if let linkInfo = link.linkInfo, let program = linkInfo.program {
                do {
                    let peFile = try PEFile(data: Data(contentsOf: program.url))
                    var icons: [NSImage] = []
                    if let resourceSection = peFile.resourceSection {
                        for entries in resourceSection.allEntries where entries.icon.isValid {
                            icons.append(entries.icon)
                        }
                    } else {
                        print("No resource section")
                        return
                    }

                    if icons.count > 0 {
                        image = icons[0]
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

struct ShortcutView: View {
    var bottle: Bottle
    @State var shortcut: Shortcut
    @State var image: NSImage?
    @Binding var loadStartMenu: Bool

    var body: some View {
        VStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 45, height: 45)
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .frame(width: 45, height: 45)
            }
            Spacer()
            Text(shortcut.link
                .deletingPathExtension()
                .lastPathComponent + "\n")
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .contextMenu {
            Button("Delete Shortcut") {
                bottle.settings.shortcuts.removeAll(where: { $0.link == shortcut.link })
                loadStartMenu.toggle()
            }
        }
        .onAppear {
            let program = Program(name: shortcut.name,
                                  url: shortcut.link,
                                  bottle: bottle)
            do {
                let peFile = try PEFile(data: Data(contentsOf: program.url))
                var icons: [NSImage] = []
                if let resourceSection = peFile.resourceSection {
                    for entries in resourceSection.allEntries where entries.icon.isValid {
                        icons.append(entries.icon)
                    }
                } else {
                    print("No resource section")
                    return
                }

                if icons.count > 0 {
                    image = icons[0]
                }
            } catch {
                print(error)
            }
        }
    }
}
