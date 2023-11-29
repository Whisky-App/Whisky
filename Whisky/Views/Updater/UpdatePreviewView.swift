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
//    enum MarkdownTextState {
//        case loaded, error, loading
//    }

    let dismiss: () -> Void
    let install: () -> Void
    @Binding var markdownText: String
    @Binding var nextVersion: String

    // let updater = SparkleUpdaterEvents.shared
    // @State var markdownTextState: MarkdownTextState = .loading
    // @State var markdownText = "# Hello"
    let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "(nil)"
    // @State var nextVersion = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("update.title")
                    .font(.title)
                    .fontWeight(.bold)
                Text(String(format: String(localized: "update.description"),
                        "v" + currentVersion,
                        nextVersion))
                Spacer()
                HStack {
                    Button("update.cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("update.update") {
                        Task(priority: .userInitiated) {
                            install()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(20)
            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("update.changeLog")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.bottom, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    Markdown {
                        markdownText
                    }
                    .markdownTheme(.basic)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            .background(.ultraThickMaterial)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            print("test:")
            print(markdownText)
        }
    }
}

#Preview {
    UpdatePreviewView(dismiss: {}, install: {}, markdownText: .constant("# Hello"), nextVersion: .constant("v1.0.0"))
        .frame(width: 600, height: 400)
}
