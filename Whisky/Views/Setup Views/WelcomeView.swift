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
    @State var rossettaReinstall: Bool = false
    @State var wineReinstall: Bool = false
    @State var gptkReinstall: Bool = false
    @State var canContinue: Bool = false
    @Binding var path: [SetupStage]
    @Binding var showSetup: Bool

    var body: some View {
        VStack {
            VStack {
                Text("setup.welcome")
                    .font(.title)
                    .fontWeight(.bold)
                Text("setup.welcome.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Form {
                if Arch.getArch() == .arm {
                    InstallStatusView(isInstalled: $rosettaInstalled,
                                      reinstall: $rossettaReinstall,
                                      name: "Rosetta")
                }
                InstallStatusView(isInstalled: $wineInstalled,
                                  reinstall: $wineReinstall,
                                  name: "Wine")
                InstallStatusView(isInstalled: $gptkInstalled,
                                  reinstall: $gptkReinstall,
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
                Button("Cancel") {
                    showSetup = false
                }
                .disabled(rosettaInstalled != true || wineInstalled != true || gptkInstalled != true)
                Button("Next") {
                    if let rosettaInstalled = rosettaInstalled,
                       let wineInstalled = wineInstalled,
                       let gptkInstalled = gptkInstalled {
                        if Arch.getArch() == .arm {
                            if !rosettaInstalled || rossettaReinstall {
                                path.append(.rosetta)
                                return
                            }
                        }

                        if !wineInstalled || wineReinstall {
                            path.append(.wineDownload)
                            return
                        }

                        if !gptkInstalled || gptkReinstall {
                            path.append(.gptk)
                            return
                        }

                        showSetup = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canContinue)
            }
        }
        .frame(width: 400, height: 250)
    }
}

struct InstallStatusView: View {
    @Binding var isInstalled: Bool?
    @Binding var reinstall: Bool
    @State var showReinstallBtn: Bool = false
    @State var name: String
    @State var text: String = NSLocalizedString("setup.install.checking",
                                                comment: "")

    var body: some View {
        HStack {
            Group {
                if reinstall {
                    Circle()
                        .foregroundColor(.yellow)
                } else if let installed = isInstalled {
                    Circle()
                        .foregroundColor(installed ? .green : .red)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(width: 10)
            Text(String.init(format: text, name))
            if showReinstallBtn {
                Spacer()
                Button("button.reinstall") {
                    if !reinstall {
                        text = NSLocalizedString("setup.install.reinstall", comment: "")
                    } else {
                        text = NSLocalizedString("setup.install.installed", comment: "")
                    }
                    reinstall = !reinstall
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
        .onHover { hovering in
            if isInstalled == true {
                showReinstallBtn = hovering
            }
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
