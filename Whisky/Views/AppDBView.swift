//
//  AppDBView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 17/04/2023.
//

import SwiftUI

struct AppDBView: View {
    @State var entries: [Entry] = []
    @State var search: String = ""
    @State var searchTask: Task<(), Never>?

    var body: some View {
        List($entries, id: \.entry) { entry in
            EntryView(entry: entry)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .onChange(of: search) { value in
            if value.isEmpty {
                entries.removeAll()
                return
            }

            if let task = searchTask {
                task.cancel()
            }

            entries.removeAll()
            entries.append(Entry(name: value, entry: 0, description: ""))

            searchTask = Task(priority: .userInitiated) {
                do {
                    try await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))
                    
                    try Task.checkCancellation()
                    entries = await AppDB.makeRequest(appName: value)
                } catch {
                    return
                }
            }
        }
        .searchable(text: $search)
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
    static var previews: some View {
        AppDBView()
    }
}
