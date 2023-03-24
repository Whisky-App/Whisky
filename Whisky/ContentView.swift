//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bottleVM: BottleVM
    @State var selected: Bottle?

    var body: some View {
        NavigationSplitView {
            List(bottleVM.bottles, id: \.self, selection: $selected) { bottle in
                Text(bottle.name)
                    .contextMenu {
                        Button {
                            bottle.delete()
                        } label: {
                            Text("Delete Bottle")
                        }
                    }
            }
        } detail: {
            if let bottle = selected {
                BottleView(bottle: bottle)
                    .id(bottle.path)
            }
        }
        .onAppear {
            bottleVM.loadBottles()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BottleVM.shared)
    }
}
