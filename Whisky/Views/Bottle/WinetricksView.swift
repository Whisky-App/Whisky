//
//  WinetricksView.swift
//  Whisky
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import SwiftUI
import WhiskyKit

struct WinetricksView: View {
    var bottle: Bottle
    @State private var winetricks: [WinetricksCategory]?
    @State private var selectedTrick: UUID?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            VStack {
                Text("winetricks.title")
                    .font(.title)
            }
            .padding(.bottom)

            // Tabbed view
            if let winetricks = winetricks {
                TabView {
                    ForEach(winetricks, id: \.category) { category in
                        Table(category.verbs, selection: $selectedTrick) {
                            TableColumn("winetricks.table.name", value: \.name)
                            TableColumn("winetricks.table.description", value: \.description)
                        }
                        .tabItem {
                            let key = "winetricks.category.\(category.category.rawValue)"
                            Text(NSLocalizedString(key, comment: ""))
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("create.cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("button.run") {
                            guard let selectedTrick = selectedTrick else {
                                return
                            }

                            let trick = winetricks.flatMap { $0.verbs }.first(where: { $0.id == selectedTrick })
                            if let trickName = trick?.name {
                                Task.detached {
                                    await Winetricks.runCommand(command: trickName, bottle: bottle)
                                }
                            }
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                Spacer()
            }
        }
        .padding()
        .onAppear {
            Task.detached {
                let tricks = await Winetricks.parseVerbs()

                await MainActor.run {
                    winetricks = tricks
                }
            }
        }
        .frame(minWidth: ViewWidth.large, minHeight: 400)
    }
}
