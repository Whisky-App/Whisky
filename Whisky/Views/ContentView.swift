//
//  ContentView.swift
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
import SemanticVersion
import Sparkle

struct ContentView: View {
    @AppStorage("selectedBottleURL") private var selectedBottleURL: URL?
    @EnvironmentObject var bottleVM: BottleVM

    let updater: SPUUpdater?

    @Binding var showSetup: Bool
    @State var selected: URL?
    @State var showBottleCreation: Bool = false
    @State var bottlesLoaded: Bool = false
    @State var showBottleSelection: Bool = false
    @State var newlyCreatedBottleURL: URL?
    @State var openedFileURL: URL?
    @State var refresh: Bool = false
    @State private var refreshAnimation: Angle = .degrees(0)

    var body: some View {
        if let updater {
            UpdateControlerView(updater: updater)
        }
        NavigationSplitView {
            ScrollViewReader { proxy in
                List(selection: $selected) {
                    ForEach(bottleVM.bottles) { bottle in
                        if bottle.inFlight {
                            HStack {
                                Text(bottle.settings.name)
                                Spacer()
                                ProgressView().controlSize(.small)
                            }
                            .opacity(0.5)
                            .id(bottle.url)
                        } else {
                            BottleListEntry(bottle: bottle, selected: $selected, refresh: $refresh)
                                .id(bottle.url)
                                .selectionDisabled(!bottle.isActive)
                        }
                    }
                }
                .onChange(of: newlyCreatedBottleURL) { _, url in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        selected = url
                        withAnimation {
                            proxy.scrollTo(url, anchor: .center)
                        }
                    }
                }
            }
        } detail: {
            if let bottle = selected {
                if let bottle = bottleVM.bottles.first(where: { $0.url == bottle }) {
                    BottleView(bottle: bottle)
                    .disabled(bottle.inFlight)
                    .id(bottle.url)
                }
            } else {
                if (bottleVM.bottles.isEmpty || bottleVM.countActive() == 0) && bottlesLoaded {
                    VStack {
                        Text("main.createFirst")
                        Button {
                            showBottleCreation.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("button.createBottle")
                            }
                            .padding(6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showBottleCreation.toggle()
                } label: {
                    Image(systemName: "plus")
                        .help("button.createBottle")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    bottleVM.loadBottles()
                    if let bottle = bottleVM.bottles.first(where: { $0.url == selected }) {
                        bottle.updateInstalledPrograms()
                    }
                    refresh.toggle()
                    withAnimation(.default) {
                        refreshAnimation = .degrees(360)
                    } completion: {
                        refreshAnimation = .degrees(0)
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .help("button.refresh")
                        .rotationEffect(refreshAnimation)
                }
            }
        }
        .sheet(isPresented: $showBottleCreation) {
            BottleCreationView(newlyCreatedBottleURL: $newlyCreatedBottleURL)
        }
        .sheet(isPresented: $showSetup) {
            SetupView(showSetup: $showSetup, firstTime: false)
        }
        .sheet(item: $openedFileURL) { url in
            FileOpenView(fileURL: url,
                         currentBottle: selected,
                         bottles: bottleVM.bottles)
        }
        .onChange(of: selected) {
            selectedBottleURL = selected
        }
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL { url in
            openedFileURL = url
        }
        .onAppear {
            bottleVM.loadBottles()
            bottlesLoaded = true

            if !bottleVM.bottles.isEmpty || bottleVM.countActive() != 0 {
                if let bottle = bottleVM.bottles.first(where: { $0.url == selectedBottleURL && $0.isActive }) {
                    selected = bottle.url
                } else {
                    selected = bottleVM.bottles[0].url
                }
            }

            if !GPTKInstaller.isGPTKInstalled() {
                showSetup = true
            }
            Task.detached {
                let updateInfo = await GPTKInstaller.shouldUpdateGPTK()

                if updateInfo.0 {
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "update.gptk.title")
                        alert.informativeText = String(format: String(localized: "update.gptk.description"),
                                                       String(GPTKInstaller.gptkVersion() ?? SemanticVersion(0, 0, 0)),
                                                       String(updateInfo.1))
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: String(localized: "update.gptk.update"))
                        alert.addButton(withTitle: String(localized: "button.removeAlert.cancel"))

                        let response = alert.runModal()

                        if response == .alertFirstButtonReturn {
                            GPTKInstaller.uninstall()
                            showSetup = true
                        }
                    }
                }
            }
        }
    }
}

struct BottleListEntry: View {
    let bottle: Bottle
    @State var showBottleRename: Bool = false
    @State var name: String = ""
    @Binding var selected: URL?
    @Binding var refresh: Bool

    var body: some View {
        Text(name)
            .opacity(bottle.isActive ? 1.0 : 0.5)
            .onAppear {
                name = bottle.settings.name
            }
            .onChange(of: refresh) {
                name = bottle.settings.name
            }
            .sheet(isPresented: $showBottleRename) {
                BottleRenameView(bottle: bottle, name: $name)
            }
            .contextMenu {
                Button("button.rename", systemImage: "pencil.line") {
                    showBottleRename.toggle()
                }
                .disabled(!bottle.isActive)
                .labelStyle(.titleAndIcon)
                Button("button.removeAlert", systemImage: "trash") {
                    showRemoveAlert(bottle: bottle)
                }
                .labelStyle(.titleAndIcon)
                Divider()
                Button("button.moveBottle", systemImage: "shippingbox.and.arrow.backward") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.canCreateDirectories = true
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.urls.first {
                                let newBottePath = url
                                    .appending(path: bottle.url.lastPathComponent)

                                bottle.move(destination: newBottePath)
                                selected = newBottePath
                            }
                        }
                    }
                }
                .disabled(!bottle.isActive)
                .labelStyle(.titleAndIcon)
                Button("button.exportBottle", systemImage: "arrowshape.turn.up.right") {
                    let panel = NSSavePanel()
                    panel.canCreateDirectories = true
                    panel.allowedContentTypes = [UTType.gzip]
                    panel.allowsOtherFileTypes = false
                    panel.isExtensionHidden = false
                    panel.nameFieldStringValue = bottle.settings.name + ".tar"
                    panel.begin { result in
                        if result == .OK {
                            if let url = panel.url {
                                Task.detached(priority: .background) {
                                    bottle.exportAsArchive(destination: url)
                                }
                            }
                        }
                    }
                }
                .disabled(!bottle.isActive)
                .labelStyle(.titleAndIcon)
                Divider()
                Button("button.showInFinder", systemImage: "folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([bottle.url])
                }
                .disabled(!bottle.isActive)
                .labelStyle(.titleAndIcon)
            }
    }

    func showRemoveAlert(bottle: Bottle) {
        let checkbox = NSButton(checkboxWithTitle: String(localized: "button.removeAlert.checkbox"),
                                target: self, action: nil)
        let alert = NSAlert()
        alert.messageText = String(format: String(localized: "button.removeAlert.msg"),
                                   bottle.settings.name)
        alert.informativeText = String(localized: "button.removeAlert.info")
        alert.alertStyle = .warning
        let delete = alert.addButton(withTitle: String(localized: "button.removeAlert.delete"))
        delete.hasDestructiveAction = true
        alert.addButton(withTitle: String(localized: "button.removeAlert.cancel"))
        if bottle.isActive {
            alert.accessoryView = checkbox
        }

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            Task(priority: .userInitiated) {
                if selected == bottle.url {
                    selected = nil
                }
                await bottle.remove(delete: checkbox.state == .on)
            }
        }
    }
}

#Preview {
    ContentView(updater: .none, showSetup: .constant(false))
        .environmentObject(BottleVM.shared)
}
