//
//  BottleView.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import SwiftUI
import UniformTypeIdentifiers
import WhiskyKit

enum BottleStage {
    case config
    case programs
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
    @State private var isLoadingInstalledPrograms: Bool = false

    private let gridLayout = [GridItem(.adaptive(minimum: 100, maximum: .infinity))]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                ZStack {
                    if pins.count > 0 {
                        LazyVGrid(columns: gridLayout, alignment: .center) {
                            ForEach(pins, id: \.url) { pin in
                                PinnedProgramView(bottle: bottle,
                                                  pin: pin,
                                                  loadStartMenu: $loadStartMenu,
                                                  path: $path)
                            }
                        }
                        .padding()
                    }

                    if isLoadingInstalledPrograms {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                                .background(Material.regular)
                                .clipShape(RoundedRectangle(cornerSize: .init(width: 16, height: 16)))
                            Spacer()
                        }
                    }
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
                }
                .formStyle(.grouped)
                .onAppear {
                    updateStartMenu()
                }
                .onChange(of: loadStartMenu) {
                    updateStartMenu()
                }
            }
            .bottomBar {
                HStack {
                    Spacer()
                    Button("button.cDrive") {
                        bottle.openCDrive()
                    }
                    Button("button.winetricks") {
                        showWinetricksSheet.toggle()
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
            .disabled(!bottle.isActive)
            .navigationTitle(bottle.settings.name)
            .sheet(isPresented: $showWinetricksSheet) {
                WinetricksView(bottle: bottle)
            }
            .navigationDestination(for: BottleStage.self) { stage in
                switch stage {
                case .config:
                    ConfigView(bottle: $bottle)
                case .programs:
                    ProgramsView(bottle: $bottle,
                                 reloadStartMenu: $loadStartMenu,
                                 path: $path)
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
        guard !isLoadingInstalledPrograms else { return }

        isLoadingInstalledPrograms = true

        DispatchQueue(label: "whisky.lock.queue").async {
            if bottle.programs.isEmpty {
                bottle.updateInstalledPrograms()
            }

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
            isLoadingInstalledPrograms = false
        }
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
    @State var program: Program?
    @State var image: NSImage?
    @State var showRenameSheet = false
    @State var name: String = ""
    @State var opening: Bool = false
    @Binding var loadStartMenu: Bool
    @Binding var path: NavigationPath

    var body: some View {
        VStack {
            Group {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                } else {
                    Image(systemName: "app.dashed")
                        .resizable()
                }
            }
            .frame(width: 45, height: 45)
            .scaleEffect(opening ? 2 : 1)
            .opacity(opening ? 0 : 1)
            Spacer()
            Text(name + "\n")
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .overlay {
            HStack {
                Spacer()
                Image(systemName: "play.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .frame(width: 16, height: 16)
            }
            .frame(width: 45, height: 45)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
        }
        .contextMenu {
            Button("button.run") {
                runProgram()
            }
            Divider()
            Button("program.config") {
                if let program {
                    path.append(program)
                }
            }
            Divider()
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
        .onTapGesture(count: 2) {
            runProgram()
        }
        .sheet(isPresented: $showRenameSheet) {
            PinRenameView(name: $name)
        }
        .onAppear {
            name = pin.name
            DispatchQueue(label: "whisky.lock.queue").async {
                program = bottle.programs.first(where: { $0.url == pin.url })
                if let program {
                    if let peFile = program.peFile {
                        image = peFile.bestIcon()
                    }
                }
            }
        }
        .onChange(of: name) {
            if let index = bottle.settings.pins.firstIndex(where: { $0.url == pin.url }) {
                bottle.settings.pins[index].name = name
            }
        }
    }

    func runProgram() {
        withAnimation(.easeIn(duration: 0.25)) {
            opening = true
        } completion: {
            withAnimation(.easeOut(duration: 0.1)) {
                opening = false
            }
        }

        if let program {
            Task {
                await program.run()
            }
        }
    }
}
