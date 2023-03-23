//
//  ContentView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct ContentView: View {
    @State var bottles: [Bottle] = []
    @State var selected: Bottle

    var body: some View {
        NavigationSplitView {
            List(bottles, id: \.self, selection: $selected) { bottle in
                Text(bottle.name)
            }
        } detail: {
            BottleView(bottle: $selected)
        }.onAppear {
            selected = bottles[0]
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let bottles = [
            Bottle("Test"),
            Bottle("Steam"),
            Bottle("Genshin Impact")
        ]

        ContentView(bottles: bottles, selected: bottles[0])
    }
}
