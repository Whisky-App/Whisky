//
//  RosettaView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct RosettaView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            VStack {
                Text("setup.rosetta")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.rosetta.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Group {
                    if model.rosettaInstalling {
                        ProgressView()
                            .scaleEffect(2)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .foregroundStyle(.green)
                    }
                }
                .frame(width: 80, height: 80)
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
    }
}
