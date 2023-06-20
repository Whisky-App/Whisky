//
//  SetupView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 19/06/2023.
//

import SwiftUI

struct SetupView: View {
    var body: some View {
        VStack {
            GPTKInstallView()
            Spacer()
            HStack {
                Button("Quit") {
                    exit(0)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Next") {
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
        .interactiveDismissDisabled()
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Welcome to Whisky")
                    .font(.title)
                Text("Let's get you setup. This won't take a minute.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Form {
                HStack {
                    if Rosetta2.isRosettaInstalled {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 10)
                        Text("Rosetta installed")
                    } else {
                        Circle()
                            .foregroundColor(.red)
                            .frame(width: 10)
                        Text("Rosetta is not installed")
                    }
                }
                HStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 10)
                    Text("Wine not installed")
                }
                HStack {
                    Circle()
                        .foregroundColor(.red)
                        .frame(width: 10)
                    Text("GPTK not installed")
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
    }
}

struct RosettaView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Installing Rosetta")
                    .font(.title)
                Text("Rosetta allows x86 code, like Wine, to run on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)
                Spacer()
            }
            Spacer()
        }
    }
}

struct WineDownloadView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Downloading Wine")
                    .font(.title)
                Text("Speeds will vary on your internet connection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack {
                    ProgressView(value: 200, total: 435)
                    HStack {
                        Text("Progress: 46% (200/435 MB)")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                Spacer()
            }
            Spacer()
        }
    }
}

struct WineInstallView: View {
    var body: some View {
        VStack {
            VStack {
                Text("Installing Wine")
                    .font(.title)
                Text("Almost there. Don't tune out yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.green)
                Spacer()
            }
            Spacer()
        }
    }
}

struct GPTKInstallView: View {
    @State private var dragOver = false
    @State private var installing = false

    var body: some View {
        VStack {
            Text("Installing GPTK")
                .font(.title)
            Text("gptkalert.init")
                .foregroundStyle(.secondary)
            Spacer()
            if installing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 80)
            } else {
                Image(systemName: "plus.square.dashed")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(dragOver ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: dragOver)
            }
            Spacer()
        }
        .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url",
                                                    completionHandler: { (data, _) in
                if let data = data,
                   let path = NSString(data: data, encoding: 4),
                   let url = URL(string: path as String) {
                    if url.pathExtension == "dmg" {
                        installing = true
                        GPTK.install(url: url)
                    } else {
                        print("Not a DMG!")
                    }
                }
            })
            return true
        }
        Spacer()
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
