//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import WhiskyKit
import SemanticVersion

struct ContentView: View {
    @AppStorage("selectedBottleURL") private var selectedBottleURL: URL?
    @EnvironmentObject var bottleVM: BottleVM
    @Binding var showSetup: Bool
    @State var selected: URL?
    @State var showBottleCreation: Bool = false
    @State var bottlesLoaded: Bool = false
    @State var showBottleSelection: Bool = false
    @State var newlyCreatedBottleURL: URL?
    @State var openedFileURL: URL?

    var body: some View {
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
                            BottleListEntry(bottle: bottle, selected: $selected)
                                .id(bottle.url)
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
                    BottleView(bottle: Binding(get: {
                        // swiftlint:disable:next force_unwrapping
                        bottleVM.bottles[bottleVM.bottles.firstIndex(of: bottle)!]
                    }, set: { newValue in
                        if let index = bottleVM.bottles.firstIndex(of: bottle) {
                            bottleVM.bottles[index] = newValue
                        }
                    }))
                    .disabled(bottle.inFlight)
                    .id(bottle.url)
                }
            } else {
                if bottleVM.bottles.isEmpty && bottlesLoaded {
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

            if !bottleVM.bottles.isEmpty {
                if let bottle = bottleVM.bottles.first(where: { $0.url == selectedBottleURL }) {
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

    var body: some View {
        Text(name)
            .onAppear {
                name = bottle.settings.name
            }
            .sheet(isPresented: $showBottleRename) {
                BottleRenameView(bottle: bottle, name: $name)
            }
            .contextMenu {
                Button("button.rename") {
                    showBottleRename.toggle()
                }
                Divider()
                Button("button.moveBottle") {
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
                            }
                        }
                    }
                }
                Button("button.exportBottle") {
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
                Divider()
                Button("button.removeAlert") {
                    showRemoveAlert(bottle: bottle)
                }
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
        alert.accessoryView = checkbox

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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(showSetup: .constant(false))
            .environmentObject(BottleVM.shared)
    }
}
