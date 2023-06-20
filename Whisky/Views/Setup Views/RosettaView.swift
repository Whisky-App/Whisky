//
//  RosettaView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct RosettaView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Installing Rosetta")
                    .font(.title)
                Text("Rosetta allows x86 code, like Wine, to run on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)
                Spacer()
            }
            Spacer()
        }
    }
}
