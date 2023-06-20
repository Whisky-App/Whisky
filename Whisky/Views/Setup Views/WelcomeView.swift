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
                if cpuArch() == .arm {
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
                }
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

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}

enum CPUArch {
    case arm
    case intel
    case unknown
}

func cpuArch() -> CPUArch {
    var size: size_t = MemoryLayout<UInt32>.size
    var type: UInt32 = 0

    sysctlbyname("hw.cputype", &type, &size, nil, 0)

    let arch: Int32 = Int32(type & ~CPU_ARCH_MASK)

    switch arch {
    case CPU_TYPE_ARM:
        return .arm
    case CPU_TYPE_X86_64, CPU_TYPE_X86:
        return .intel
    default:
        return .unknown
    }
}
