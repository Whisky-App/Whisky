//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bottleVM: BottleVM

    @State var selected: Bottle

    var body: some View {
        NavigationSplitView {
            List(bottleVM.bottles, id: \.path, selection: $selected) { bottle in
                Text(bottle.name)
            }
        } detail: {
            BottleView(bottle: $selected)
        }
        .onAppear {
            bottleVM.loadBottles()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selected: BottleVM.shared.bottles[0])
            .environmentObject(BottleVM.shared)
    }
}
