//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bottleVM: BottleVM
    @State var selected: URL?
    @State var showBottleCreation: Bool = false

    var body: some View {
        NavigationSplitView {
            List(bottleVM.bottles, id: \.url, selection: $selected) { bottle in
                BottleListEntry(bottle: .constant(bottle))
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
            BottleCreationView()
        }
        .onAppear {
            bottleVM.loadBottles()
        }
    }
}
 
struct BottleListEntry: View {
    @Binding var bottle: Bottle
    @State var showBottleRename: Bool = false

    var body: some View {
        Text(bottle.name)
            .sheet(isPresented: $showBottleRename) {
                BottleRenameView(bottle: .constant(bottle))
            }
            .contextMenu {
                Button {
                    showBottleRename.toggle()
                } label: {
                    Text("button.renameBottle")
                }
                Button {
                    showDeleteAlert(bottle: bottle)
                } label: {
                    Text("button.deleteBottle")
                }
            }
    }

    func showDeleteAlert(bottle: Bottle) {
        let alert = NSAlert()
        alert.messageText = String(format: NSLocalizedString("button.deleteAlert.msg",
                                                             comment: ""),
                                   bottle.name)
        alert.informativeText = NSLocalizedString("button.deleteAlert.info", comment: "")
        alert.alertStyle = .warning
        let delete = alert.addButton(withTitle: NSLocalizedString("button.deleteAlert.delete", comment: ""))
        delete.hasDestructiveAction = true
        alert.addButton(withTitle: NSLocalizedString("button.deleteAlert.cancel", comment: ""))

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
