//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import WhiskyKit

enum BottleStage {
    case config
    case programs
    case info
}

struct BottleView: View {
    @Binding var bottle: Bottle
    @State private var path = NavigationPath()
    @State var programLoading: Bool = false
    @State var pins: [PinnedProgram] = []
    // We don't actually care about the value
    // This just provides a way to trigger a refresh
    @State var loadStartMenu: Bool = false
    @State var showWinetricksSheet: Bool = false

    private let gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                ScrollView {
                    if pins.count > 0 {
                        LazyVGrid(columns: gridLayout, alignment: .center) {
                            ForEach(pins, id: \.url) { pin in
                                PinnedProgramView(bottle: bottle,
                                                  pin: pin,
                                                  loadStartMenu: $loadStartMenu)
                                .overlay {
                                    HStack {
                                        Spacer()
                                        Button {
                                            let program = Program(name: pin.name,
                                                                  url: pin.url,
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
                                    .frame(width: 45, height: 45)
                                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
                                }
                            }
                        }
                        .padding()
                    }
                    Form {
                        NavigationLink(value: BottleStage.programs) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14, alignment: .center)
                                Text("tab.programs")
                            }
                        }
                        NavigationLink(value: BottleStage.config) {
                            HStack {
                                Image(systemName: "gearshape")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14, alignment: .center)
                                Text("tab.config")
                            }
                        }
                        NavigationLink(value: BottleStage.info) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 14, height: 14, alignment: .center)
                                Text("tab.info")
                            }
                        }
                    }
                    .formStyle(.grouped)
                    .onAppear {
                        updateStartMenu()
                    }
                    .onChange(of: loadStartMenu) {
                        updateStartMenu()
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Button("button.winetricks") {
                        showWinetricksSheet.toggle()
                    }
                    Button("button.cDrive") {
                        bottle.openCDrive()
                    }
                    Button("button.run") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        panel.allowedContentTypes = [UTType.exe,
                                                     UTType(exportedAs: "com.microsoft.msi-installer"),
                                                     UTType(exportedAs: "com.microsoft.bat")]
                        panel.directoryURL = bottle.url.appending(path: "drive_c")
                        panel.begin { result in
                            programLoading = true
                            Task(priority: .userInitiated) {
                                if result == .OK {
                                    if let url = panel.urls.first {
                                        do {
                                            if url.pathExtension == "bat" {
                                                try await Wine.runBatchFile(url: url, bottle: bottle)
                                            } else {
                                                try await Wine.runExternalProgram(url: url, bottle: bottle)
                                            }
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
            .sheet(isPresented: $showWinetricksSheet) {
                WinetricksView(bottle: bottle)
            }
            .navigationDestination(for: BottleStage.self) { stage in
                switch stage {
                case .config:
                    ConfigView(bottle: $bottle)
                case .programs:
                    ProgramsView(bottle: bottle,
                                 reloadStartMenu: $loadStartMenu,
                                 path: $path)
                case .info:
                    InfoView(bottle: bottle)
                }
            }
            .navigationDestination(for: Program.self) { program in
                ProgramView(program: Binding(get: {
                    // swiftlint:disable:next force_unwrapping
                    bottle.programs[bottle.programs.firstIndex(of: program)!]
                }, set: { newValue in
                    if let index = bottle.programs.firstIndex(of: program) {
                        bottle.programs[index] = newValue
                    }
                }))
            }
        }
    }

    func updateStartMenu() {
        bottle.programs = bottle.updateInstalledPrograms()
        let startMenuPrograms = bottle.getStartMenuPrograms()
        for startMenuProgram in startMenuPrograms {
            for program in bottle.programs where
            // For some godforsaken reason "foo/bar" != "foo/Bar" so...
            program.url.path().caseInsensitiveCompare(startMenuProgram.url.path()) == .orderedSame {
                program.pinned = true
                if !bottle.settings.pins.contains(where: { $0.url == program.url }) {
                    bottle.settings.pins.append(PinnedProgram(name: program.name
                                                                    .replacingOccurrences(of: ".exe", with: ""),
                                                              url: program.url))
                }
            }
        }

        pins = bottle.settings.pins
    }
}

struct WinetricksView: View {
    var bottle: Bottle
    @State var winetricksCommand: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("winetricks.title")
                    .bold()
                Spacer()
            }
            Divider()
            TextField(String(), text: $winetricksCommand)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .labelsHidden()
            Spacer()
            HStack {
                Spacer()
                Button("create.cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("button.run") {
                    Task.detached(priority: .userInitiated) {
                        await Winetricks.runCommand(command: winetricksCommand, bottle: bottle)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350, height: 140)
    }
}

struct PinnedProgramView: View {
    var bottle: Bottle
    @State var pin: PinnedProgram
    @State var image: NSImage?
    @State var showRenameSheet = false
    @State var name: String = ""
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
            Text(name + "\n")
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .contextMenu {
            Button("button.rename") {
                showRenameSheet.toggle()
            }
            Button("pin.unpin") {
                bottle.settings.pins.removeAll(where: { $0.url == pin.url })
                for program in bottle.programs where program.url == pin.url {
                    program.pinned = false
                }
                loadStartMenu.toggle()
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            PinRenameView(name: $name)
        }
        .onAppear {
            let program = Program(name: pin.name,
                                  url: pin.url,
                                  bottle: bottle)
            if let peFile = program.peFile {
                image = peFile.bestIcon()
            }
            name = pin.name
        }
        .onChange(of: name) {
            if let index = bottle.settings.pins.firstIndex(where: { $0.url == pin.url }) {
                bottle.settings.pins[index].name = name
            }
        }
    }
}
