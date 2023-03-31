//
//  InfoView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI

struct InfoView: View {
    @State var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Text("info.path") + Text(" \(bottle.url.path)")
                Spacer()
            }
            HStack {
                Text("info.wine") + Text(" \(bottle.settings.settings.wineVersion)")
                Spacer()
            }
            .padding(.vertical)
            HStack {
                Text("info.win") + Text(" \(bottle.settings.settings.windowsVersion.pretty())")
                Spacer()
            }
            Spacer()
        }
        .padding()
        .navigationTitle("\(bottle.name) \(NSLocalizedString("tab.info", comment: ""))")
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(bottle: Bottle())
    }
}
