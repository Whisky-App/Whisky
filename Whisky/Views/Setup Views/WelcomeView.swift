//
//  WelcomeView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

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
                if cpuArch() == .arm {
                    HStack {
                        Circle()
                            .foregroundColor(.green)
                            .frame(width: 10)
                        Text("Rosetta installed")
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
