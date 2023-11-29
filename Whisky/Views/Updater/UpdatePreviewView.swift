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
    enum MarkdownTextState {
        case loaded, error, loading
    }

    let dismiss: () -> Void
    let install: () -> Void

    let updater = SparkleUpdaterEvents.shared
    @State var markdownTextState: MarkdownTextState = .loading
    @State var markdownText = "# Hello"
    @State var currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "(nil)"
    @State var nextVersion = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("update.title")
                    .font(.title)
                    .fontWeight(.bold)
                Text(markdownTextState != .loaded
                     ? String(localized: "update.description")
                     : String(format: String(localized: "update.descriptionLoaded"),
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
                if markdownTextState == .loading {
                    ProgressView()
                } else if markdownTextState == .error {
                    VStack(spacing: 12) {
                        Text("update.changeLogFailed")
                        Button("update.retryChangeLog") {
                            Task(priority: .userInitiated) {
                                await getChangelog()
                            }
                        }
                    }
                } else {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
            .background(.ultraThickMaterial)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task(priority: .userInitiated) {
                await getChangelog()
            }
        }
    }

    func getChangelog() async {
        withAnimation { markdownTextState = .loading }
        let ghOwner = (Bundle.main.object(forInfoDictionaryKey: "GithubRepoOwner") as? String) ?? "Whisky-App"
        let ghRepo = (Bundle.main.object(forInfoDictionaryKey: "GithubRepoName") as? String) ?? "Whisky"

        // Make a request to the Github API to get the latest release
        // Append path not using string interpolation to non-urlencoded paths
        guard let url = URL(string: "https://api.github.com/")?
            .appending(path: "repos")
            .appending(path: ghOwner)
            .appending(path: ghRepo)
            .appending(path: "releases")
            .appending(path: "latest")
        else {
            withAnimation { markdownTextState = .error }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WhiskyApp", forHTTPHeaderField: "User-Agent")

        let data: Data
        do {
            let (dataInfo, _) = try (await URLSession.shared.data(for: request))
            data = dataInfo
        } catch {
            print("Changelog request failed: \(error)")
            withAnimation { markdownTextState = .error }
            return
        }

        // Decode the JSON
        struct Release: Codable {
            let body: String
            let tagName: String

            enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
                case body
                case tagName = "tag_name"
            }
        }

        let release: Release
        do {
            release = try JSONDecoder().decode(Release.self, from: data)
        } catch {
            print("Failed to decode release: \(error)")
            withAnimation { markdownTextState = .error }
            return
        }

        withAnimation {
            markdownText = release.body
            nextVersion = release.tagName
            markdownTextState = .loaded
        }
    }
}

#Preview {
    UpdatePreviewView(dismiss: {}, install: {})
        .frame(width: 600, height: 400)
}
