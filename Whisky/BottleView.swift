//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct BottleView: View {
    @Binding var bottle: Bottle

    var body: some View {
        VStack {
            HStack {
                Toggle("DXVK", isOn: $bottle.dxvk)
                    .toggleStyle(.switch)
                Toggle("Winetricks", isOn: $bottle.winetricks)
                    .toggleStyle(.switch)
                Spacer()
            }
            Divider()
            Spacer()
        }
        .padding()
        .navigationTitle(bottle.name)
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        let bottle = Bottle("Steam")

        BottleView(bottle: .constant(bottle))
            .frame(width: 500, height: 300)
    }
}
