//
//  InfoView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI
import WhiskyKit

struct InfoView: View {
    let bottle: Bottle
    @State var prettyPath: String = ""

    var body: some View {
        Form {
            Section("info.title") {
                InfoItem(label: String(localized: "info.path"),
                         value: prettyPath)
                .contextMenu {
                    Button("info.path.copy") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bottle.url.path, forType: .string)
                    }
                }
                InfoItem(label: String(localized: "info.wine"),
                         value: String(bottle.settings.wineVersion))
                if let version = GPTKInstaller.gptkVersion() {
                    InfoItem(label: String(localized: "info.gptk"),
                             value: String(version))
                }
                InfoItem(label: String(localized: "info.win"),
                         value: bottle.settings.windowsVersion.pretty())
            }
        }
        .formStyle(.grouped)
        .navigationTitle("tab.info")
        .onAppear {
            prettyPath = bottle.url.prettyPath()
        }
    }
}

struct InfoItem: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .padding(5)
                .background(.background)
                .cornerRadius(5)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
        }
    }
}
