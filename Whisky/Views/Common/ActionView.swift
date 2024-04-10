//
//  ActionView.swift
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

struct ActionView: View {
    let text: LocalizedStringKey
    let subtitle: String
    let actionName: LocalizedStringKey
    let action: () -> Void

    init(
        text: LocalizedStringKey,
        subtitle: String = "",
        actionName: LocalizedStringKey,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.subtitle = subtitle
        self.actionName = actionName
        self.action = action
    }

    var body: some View {
        HStack(alignment: subtitle.isEmpty ? .center : .top) {
            VStack(alignment: .leading) {
                Text(text)
                    .foregroundStyle(.primary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .truncationMode(.middle)
                        .lineLimit(2)
                        .help(subtitle)
                }
            }
            Spacer()
            Button(actionName) {
                action()
            }
        }
    }
}
