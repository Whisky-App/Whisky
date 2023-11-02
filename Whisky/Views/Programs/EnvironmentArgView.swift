//
//  EnvironmentArgView.swift
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

enum KeySection {
    case key, value
}

enum Focusable: Hashable {
    case row(id: UUID, section: KeySection)
}

class Key: Identifiable {
    static func == (lhs: Key, rhs: Key) -> Bool {
        return lhs.id == rhs.id
    }

    var id: UUID = UUID()
    @Published var key: String
    @Published var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

struct EnvironmentArgView: View {
    @ObservedObject var program: Program
    @FocusState var focus: Focusable?
    @State var environmentKeys: [Key] = []
    @State var movedToIllegalKey = false

    var body: some View {
        Section {
            VStack {
                ForEach(environmentKeys, id: \.id) { key in
                    KeyItem(environmentKeys: $environmentKeys, key: key, focus: _focus)
                }
            }
            .onAppear {
                environmentKeys = program.settings.environment.map { (key: String, value: String) in
                    return Key(key: key, value: value)
                }
            }
            .onDisappear {
                program.settings.environment.removeAll()
                for key in environmentKeys {
                    program.settings.environment[key.key] = key.value
                }
            }
        } header: {
            HStack {
                Text("program.env").frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Button("environment.add", systemImage: "plus") {
                    createNewKey()
                }
                .buttonStyle(.plain)
                .labelStyle(.titleAndIcon)
            }
        }
        .onChange(of: focus) { oldValue, newValue in
            switch oldValue {
            case .row(let id, _):
                if let key = environmentKeys.first(where: { $0.id == id }) {
                    switch newValue {
                    case .row(let newId, _):
                        // Remove empty keys
                        if key.key.isEmpty && newId != id {
                            environmentKeys.removeAll(where: { $0.id == key.id })
                            focus = nil
                            return
                        }
                    case .none: break
                    }

                    // A key with this value already exists, so its invalid
                    if environmentKeys.contains(where: { $0.key == key.key && $0.id != key.id }) && !movedToIllegalKey {
                        movedToIllegalKey = true
                        focus = .row(id: key.id, section: .key)
                        return
                    }

                    movedToIllegalKey = false
                }
            case .none: break
            }
        }
    }

    func createNewKey() {
        if let key = environmentKeys.first(where: { $0.key.isEmpty }) {
            focus = .row(id: key.id, section: .key)
            return
        }

        let key = Key(key: "", value: "")
        environmentKeys.append(key)
        focus = .row(id: key.id, section: .key)
    }
}

struct KeyItem: View {
    @Binding var environmentKeys: [Key]
    @State var key: Key
    @FocusState var focus: Focusable?

    var body: some View {
        HStack {
            TextField(String(), text: $key.key)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(maxHeight: .infinity)
                .focused($focus, equals: .row(id: key.id, section: .key))
                .onChange(of: key.key) {
                    key.key = key.key.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .onSubmit {
                    // Try to move on to value
                    focus = .row(id: key.id, section: .value)
                }
            TextField(String(), text: $key.value)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .frame(maxHeight: .infinity)
                .focused($focus, equals: .row(id: key.id, section: .value))

            Button("environment.remove", systemImage: "trash") {
                environmentKeys.removeAll(where: { $0.id == key.id })
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
        }
    }
}
