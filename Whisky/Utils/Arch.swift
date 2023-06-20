//
//  Arch.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import Foundation

enum CPUArch {
    case arm
    case intel
    case unknown
}

struct Arch {
    static func getArch() -> CPUArch {
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
}
