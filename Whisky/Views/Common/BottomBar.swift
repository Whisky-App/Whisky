//
//  BottomBar.swift
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

extension View {
    func bottomBar<Content>(
        @ViewBuilder content: () -> Content
    ) -> some View where Content: View {
        modifier(BottomBarViewModifier(barContent: content()))
    }
}

private struct BottomBarViewModifier<BarContent>: ViewModifier where BarContent: View {
    var barContent: BarContent

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    barContent
                }
                .background(.regularMaterial)
                .buttonStyle(BottomBarButtonStyle())
            }
    }
}

struct BottomBarButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            configuration.label
                .foregroundStyle(.foreground)
        }
    }
}

#Preview {
    Form {
        Text(String("Hello World"))
    }
    .formStyle(.grouped)
    .bottomBar {
        HStack {
            Spacer()
            Button {
            } label: {
                Text(String("Button 1"))
            }
            Button {
            } label: {
                Text(String("Button 2"))
            }
        }
        .padding()
    }
}
