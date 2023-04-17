//
//  AppDBView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 17/04/2023.
//

import SwiftUI

struct AppDBView: View {
    @State var entries: [Entry]

    var body: some View {
        List($entries, id: \.entry) { entry in
            EntryView(entry: entry)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .onAppear {
            Task(priority: .userInitiated) {
                entries = await AppDB.makeRequest(appName: "Steam")
            }
        }
    }
}

struct EntryView: View {
    @Binding var entry: Entry

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(entry.name)
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                HStack {
                    Text(entry.description)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    Spacer()
                }
            }
            Spacer()
            Text(String(entry.entry))
                .monospaced()
        }
    }
}

struct AppDBView_Previews: PreviewProvider {
    @State static var entries: [Entry] = []

    static var previews: some View {
        AppDBView(entries: entries)
    }
}
