//
//  WelcomeView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct WelcomeView: View {
    @State var rosettaInstalled: Bool?
    @State var wineInstalled: Bool?
    @State var gptkInstalled: Bool?
    @State var canContinue: Bool = false
    @Binding var path: [SetupStage]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            VStack {
                Text("setup.welcome")
                    .font(.title)
                Text("setup.welcome.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Form {
                if Arch.getArch() == .arm {
                    InstallStatusView(isInstalled: $rosettaInstalled,
                                      name: "Rosetta")
                }
                InstallStatusView(isInstalled: $wineInstalled,
                                  name: "Wine")
                InstallStatusView(isInstalled: $gptkInstalled,
                                  name: "GPTK")
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .onAppear {
                Task {
                    rosettaInstalled = Rosetta2.isRosettaInstalled
                    wineInstalled = WineInstaller.isWineInstalled()
                    gptkInstalled = GPTK.isGPTKInstalled()
                    canContinue = true
                }
            }
            Spacer()
            HStack {
                Button("Quit") {
                    exit(0)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Next") {
                    if let rosettaInstalled = rosettaInstalled,
                       let wineInstalled = wineInstalled,
                       let gptkInstalled = gptkInstalled {
                        if Arch.getArch() == .arm {
                            if !rosettaInstalled {
                                path.append(.rosetta)
                                return
                            }
                        }

                        if !wineInstalled {
                            path.append(.wineDownload)
                            return
                        }

                        if !gptkInstalled {
                            path.append(.gptk)
                            return
                        }

                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
            }
        }
    }
}

struct InstallStatusView: View {
    @Binding var isInstalled: Bool?
    @State var name: String
    @State var text: String = NSLocalizedString("setup.install.checking",
                                                comment: "")

    var body: some View {
        HStack {
            Group {
                if let installed = isInstalled {
                    Circle()
                        .foregroundColor(installed ? .green : .red)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(width: 10)
            Text(String.init(format: text, name))
        }
        .onChange(of: isInstalled) { _ in
            if let installed = isInstalled {
                if installed {
                    text = NSLocalizedString("setup.install.installed", comment: "")
                } else {
                    text = NSLocalizedString("setup.install.notInstalled", comment: "")
                }
            } else {
                text = NSLocalizedString("setup.install.checking", comment: "")
            }
        }
    }
}
