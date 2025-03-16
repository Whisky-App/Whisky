//
//  CollapsibleView.swift
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

struct CollapsibleView<Header: View, Content: View>: View {
    @State private var isExpanded: Bool = false
    let header: () -> Header
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                isExpanded.toggle()
            }, label: {
                HStack {
                    header()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding()
            })
            if isExpanded {
                content()
                    .padding([.leading, .trailing, .bottom])
            }
        }
        .background(RoundedRectangle(cornerRadius: 10).stroke())
    }
}
