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
        Form {
            Section("info.title") {
                InfoItem(label: NSLocalizedString("info.path", comment: ""),
                         value: bottle.url.path)
                .contextMenu {
                    Button {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bottle.url.path, forType: .string)
                    } label: {
                        Text("info.path.copy")
                    }
                }
                InfoItem(label: NSLocalizedString("info.wine", comment: ""),
                         value: bottle.settings.wineVersion)
                InfoItem(label: NSLocalizedString("info.win", comment: ""),
                         value: bottle.settings.windowsVersion.pretty())
            }
        }
        .formStyle(.grouped)
        .navigationTitle("\(bottle.name) \(NSLocalizedString("tab.info", comment: ""))")
    }
}

struct InfoItem: View {
    @State var label: String
    @State var value: String

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

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(bottle: Bottle())
    }
}
