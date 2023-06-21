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

    var body: some View {
        NavigationSplitView {
            VStack {
                if bottleVM.bottles.isEmpty &&
                    bottleVM.inFlightBottles.isEmpty {
                    Text("main.noBottles")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(10)
                } else {
                    List(selection: $selected) {
                        ForEach(bottleVM.bottles, id: \.url) { bottle in
                            BottleListEntry(bottle: bottle, selected: $selected)
                        }
                        ForEach(bottleVM.inFlightBottles, id: \.self) { inFlight in
                            HStack {
                                Text(inFlight)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 200, maxWidth: 200, maxHeight: .infinity)
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
                    .id(bottle.url)
                }
            } else {
                if bottleVM.bottles.isEmpty &&
                    bottleVM.inFlightBottles.isEmpty {
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
            BottleCreationView()
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
