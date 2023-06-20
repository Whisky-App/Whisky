//
//  WelcomeView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Welcome to Whisky")
                    .font(.title)
                Text("Let's get you setup. This won't take a minute.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Form {
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 10)
                    Text("Rosetta installed")
                }
                HStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 10)
                    Text("Wine not installed")
                }
                HStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 10)
                    Text("GPTK not installed")
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
    }
}
