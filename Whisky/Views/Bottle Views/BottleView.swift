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

    private let gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        VStack {
            ScrollView {
                if startMenuPrograms.count > 0 {
                    NavigationStack {
                        LazyVGrid(columns: gridLayout, alignment: .center) {
                            ForEach(startMenuPrograms, id: \.self) { link in
                                NavigationLink {
                                    if let link = link.linkInfo, let program = link.program {
                                        ProgramView(program: .constant(program))
                                    }
                                } label: {
                                    ShellLinkView(link: link)
                                }
                                .buttonStyle(.plain)
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
                        NavigationLink {
                            RegistryView(registry: $bottle.registry)
                        } label: {
                            Label("tab.registry", systemImage: "list.bullet.rectangle")
                        }
                    }
                    .formStyle(.grouped)
                    .onAppear {
                        startMenuPrograms = bottle.updateStartMenuPrograms()
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
                    panel.begin { result in
                        programLoading = true
                        Task(priority: .userInitiated) {
                            if result == .OK {
                                if let url = panel.urls.first {
                                    let program = Program(name: url.lastPathComponent,
                                                          url: url,
                                                          bottle: bottle)
                                    await program.run()
                                    programLoading = false
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
    @State var link: ShellLinkHeader
    @State var image: NSImage?

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
