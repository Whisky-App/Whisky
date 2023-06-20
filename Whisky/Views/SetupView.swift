//
//  SetupView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import SwiftUI

struct SetupView: View {
    var body: some View {
        VStack {
            GPTKInstallView()
            Spacer()
            HStack {
                Button("Quit") {
                    exit(0)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Next") {
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
        .interactiveDismissDisabled()
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}