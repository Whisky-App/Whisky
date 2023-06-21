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
                            BottleListEntry(bottle: bottle)
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
            if let url = selected {
                if let bottle = bottleVM.bottles.first(where: { $0.url == url }) {
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
            if WineInstaller.shouldUpdateWine() {
                showSetup = true
            }
        }
    }
}

struct BottleListEntry: View {
    let bottle: Bottle
    @State var showBottleRename: Bool = false

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
