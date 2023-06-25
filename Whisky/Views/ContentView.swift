//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bottleVM: BottleVM
    @AppStorage("showSetup") private var showSetup = true
    @State var selected: URL?
    @State var showBottleCreation: Bool = false
    @State var bottlesLoaded: Bool = false
    @State var newlyCreatedBottleURL: URL?

    var body: some View {
        NavigationSplitView {
            ScrollViewReader { proxy in
                List(selection: $selected) {
                    ForEach(bottleVM.bottles, id: \.url) { bottle in
                        if bottle.inFlight {
                            HStack {
                                Text(bottle.name)
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
                .onChange(of: newlyCreatedBottleURL) { url in
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
            if WineInstaller.shouldUpdateWine() {
                showSetup = true
            }
            if ProcessInfo().operatingSystemVersion.majorVersion < 14 {
                Task {
                    let alert = NSAlert()
                    alert.messageText = String(localized: "alert.macos")
                    alert.informativeText = String(localized: "alert.macos.info")
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: String(localized: "button.ok"))
                    alert.runModal()
                }
            }
        }
    }
}

struct BottleListEntry: View {
    let bottle: Bottle
    @State var showBottleRename: Bool = false
    @Binding var selected: URL?

    var body: some View {
        Text(bottle.name)
            .sheet(isPresented: $showBottleRename) {
                BottleRenameView(bottle: bottle)
            }
            .contextMenu {
                Button("button.renameBottle") {
                    showBottleRename.toggle()
                }
                Button("button.deleteBottle") {
                    showDeleteAlert(bottle: bottle)
                }
            }
    }

    func showDeleteAlert(bottle: Bottle) {
        let alert = NSAlert()
        alert.messageText = String(format: String(localized: "button.deleteAlert.msg"),
                                   bottle.name)
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
        ContentView()
            .environmentObject(BottleVM.shared)
    }
}
