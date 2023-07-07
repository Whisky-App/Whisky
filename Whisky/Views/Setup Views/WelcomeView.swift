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
    @State var shouldCheckInstallStatus: Bool = false
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
                                      shouldCheckInstallStatus: $shouldCheckInstallStatus,
                                      name: "Rosetta")
                }
                InstallStatusView(isInstalled: $wineInstalled,
                                  shouldCheckInstallStatus: $shouldCheckInstallStatus,
                                  showUninstall: true,
                                  name: "Wine")
                InstallStatusView(isInstalled: $gptkInstalled,
                                  shouldCheckInstallStatus: $shouldCheckInstallStatus,
                                  showUninstall: true,
                                  name: "GPTK")
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .onAppear {
                checkInstallStatus()
            }
            .onChange(of: shouldCheckInstallStatus) { _ in
                checkInstallStatus()
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

                        showSetup = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(width: 400, height: 250)
    }

    func checkInstallStatus() {
        rosettaInstalled = Rosetta2.isRosettaInstalled
        wineInstalled = WineInstaller.isWineInstalled()
        gptkInstalled = GPTK.isGPTKInstalled()
    }
}

struct InstallStatusView: View {
    @Binding var isInstalled: Bool?
    @Binding var shouldCheckInstallStatus: Bool
    @State var showUninstall: Bool = false
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
            Spacer()
            if let installed = isInstalled {
                if installed && showUninstall {
                    Button("setup.uninstall") {
                        uninstall()
                    }
                }
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

    func uninstall() {
        if name == "Wine" {
            WineInstaller.uninstall()
        }
        if name == "GPTK" {
            GPTK.uninstall()
        }
        shouldCheckInstallStatus.toggle()
    }
}
