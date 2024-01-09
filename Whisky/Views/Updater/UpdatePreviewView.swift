//
//  UpdateUI.swift
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
import Sparkle
import MarkdownUI

struct UpdatePreviewView: View {
    let dismiss: () -> Void
    let install: () -> Void
    let markdownText: String?
    let nextVersion: String
    let nextVersionNumber: String

    private let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    private let currentVersionNumber = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "0"

    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 12) {
                BundleIcon().frame(width: 80, height: 80)
                VStack(alignment: .center, spacing: 2) {
                    Text("app.name")
                        .font(.title)
                        .fontWeight(.bold)
                    Text(String(format: String(localized: "app.version"),
                                "v" + currentVersion,
                                currentVersionNumber))
                    .opacity(0.8)
                }
                Text(String(format: String(localized: "update.description"),
                        "v" + currentVersion,
                        currentVersionNumber,
                        "v" + nextVersion,
                        nextVersionNumber))
                .opacity(0.8)
                .multilineTextAlignment(.center)
                Spacer()
                    .frame(height: 8)
                VStack(spacing: 12) {
                    Button {
                        Task(priority: .userInitiated) {
                            install()
                        }
                    } label: {
                        Text("update.update")
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    Button {
                        dismiss()
                    } label: {
                        Text("button.cancel")
                            .padding(8)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .frame(width: 200)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            ScrollView {
                VStack(alignment: .leading) {
                    Text("update.newUpdate")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                if let markdownText = markdownText {
                    VStack(alignment: .leading) {
                        Markdown(markdownText)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                } else {
                    Text("update.noChangeLog")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(20)
            .background(.ultraThickMaterial)
        }
        .frame(width: 700, height: 400)
    }
}

#Preview {
    UpdatePreviewView(dismiss: {}, install: {}, markdownText: "# Hello", nextVersion: "1.0.0", nextVersionNumber: "10")
}
