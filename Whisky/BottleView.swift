//
//  BottleView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 23/03/2023.
//

import SwiftUI

struct BottleView: View {
    @Binding var bottle: Bottle
    @State var wineVersion: String = "Wine Version: "

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
            HStack {
                Text(wineVersion)
                Spacer()
            }
            HStack {
                Button("winecfg") {
                    Task(priority: .userInitiated) {
                        do {
                            try await print(Wine.cfg(bottle: bottle))
                        } catch {
                            print("Failed to launch winecfg")
                        }
                    }
                }
                Button("Open C Drive") {
                    bottle.openCDrive()
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .navigationTitle(bottle.name)
        .onAppear {
            Task(priority: .background) {
                do {
                    try await wineVersion += Wine.version()
                } catch {
                    wineVersion += "Failed"
                }
            }
        }
    }
}

struct BottleView_Previews: PreviewProvider {
    static var previews: some View {
        let bottle = Bottle()

        BottleView(bottle: .constant(bottle))
            .frame(width: 500, height: 300)
    }
}
