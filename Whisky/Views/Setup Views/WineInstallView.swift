//
//  WineInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineInstallView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            VStack {
                Text("setup.wine.install")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.wine.install.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if model.wineInstalling {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 80)
                } else {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.green)
                }
                Spacer()
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
    }
}
