//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import WhiskyKit

struct ContentView: View {
    @EnvironmentObject var bottleVM: BottleVM
    @Binding var showSetup: Bool
    @State var selected: URL?
    @State var showBottleCreation: Bool = false
    @State var bottlesLoaded: Bool = false
    @State var newlyCreatedBottleURL: URL?

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
                } else {
                    Text("main.noneSelected")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .opacity(0.5)
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
            SetupView(showSetup: $showSetup)
        }
        .onAppear {
            bottleVM.loadBottles()
            bottlesLoaded = true
            if !GPTKInstaller.isGPTKInstalled() {
                showSetup = true
            }
            if GPTKInstaller.shouldUpdateGPTK() {
                GPTKInstaller.uninstall()
                showSetup = true
            }
        }
    }
}

struct BottleListEntry: View {
    let bottle: Bottle
    @State var showBottleRename: Bool = false
    @Binding var selected: URL?

    var body: some View {
        Text(bottle.settings.name)
            .sheet(isPresented: $showBottleRename) {
                BottleRenameView(bottle: bottle)
            }
            .contextMenu {
                Button("button.renameBottle") {
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
                                    .appendingPathComponent(bottle.url.lastPathComponent)

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
                Button("button.deleteBottle") {
                    showDeleteAlert(bottle: bottle)
                }
            }
    }

    func showDeleteAlert(bottle: Bottle) {
        let alert = NSAlert()
        alert.messageText = String(format: String(localized: "button.deleteAlert.msg"),
                                   bottle.settings.name)
        alert.informativeText = String(localized: "button.deleteAlert.info")
        alert.alertStyle = .warning
        let delete = alert.addButton(withTitle: String(localized: "button.deleteAlert.delete"))
        delete.hasDestructiveAction = true
        alert.addButton(withTitle: String(localized: "button.deleteAlert.cancel"))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            Task(priority: .userInitiated) {
                if selected == bottle.url {
                    selected = nil
                }
                await bottle.delete()
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
