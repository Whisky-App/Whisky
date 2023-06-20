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
                Text("Welcome to Whisky")
                    .font(.title)
                Text("Let's get you setup. This won't take a minute.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            Spacer()
            Form {
                if cpuArch() == .arm {
                    InstallStatusView(isInstalled: $rosettaInstalled,
                                      text: "Rosetta")
                }
                InstallStatusView(isInstalled: $wineInstalled,
                                  text: "Wine")
                InstallStatusView(isInstalled: $gptkInstalled,
                                  text: "GPTK")
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .onAppear {
                Task {
                    // Set bools here
                }
            }
        }
    }
}

struct InstallStatusView: View {
    @Binding var isInstalled: Bool?
    @State var text: String

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
            Text("Checking \(text) installation...")
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
