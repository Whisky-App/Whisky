//
//  WineInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WineInstallView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Installing Wine")
                    .font(.title)
                Text("Almost there. Don't tune out yet.")
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
