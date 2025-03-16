//
//  MonitorView.swift
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

import Foundation
import Darwin
import SwiftUI
import WhiskyKit

typealias PID = Int32

// ethan: sysctl my beloved
enum SysctlHelper {
    static func getWine64PreloaderPids() -> [PID]? {
        var sysctlName = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0

        let sysctlForSizeResult = sysctl(&sysctlName, UInt32(sysctlName.count), nil, &size, nil, 0)
        if sysctlForSizeResult != 0 {
            print("Error getting size of process list")
            return nil
        }

        let processCount = size / MemoryLayout<kinfo_proc>.stride
        let processListStart = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: processCount)
        defer { processListStart.deallocate() }

        let sysctlForListResult = sysctl(&sysctlName, UInt32(sysctlName.count), processListStart, &size, nil, 0)
        if sysctlForListResult != 0 {
            print("Error getting process list")
            return nil
        }

        let processList = UnsafeBufferPointer(start: processListStart, count: processCount)
        var ids: [PID] = []

        for rawProcessInfo in processList {
            let name = withUnsafePointer(to: rawProcessInfo.kp_proc.p_comm) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                    String(cString: $0)
                }
            }

            if name == "wine64-preloader" {
                ids.append(rawProcessInfo.kp_proc.p_pid)
            }
        }

        return ids
    }

    static func workingDirectory(for pid: PID) -> String? {
        var vnodeInfo = proc_vnodepathinfo()
        let size = MemoryLayout<proc_vnodepathinfo>.size
        let resultingSize = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &vnodeInfo, Int32(size))

        guard resultingSize == Int32(size) else {
            print("proc_pidinfo failed for pid \(pid) with result \(resultingSize)")
            return nil
        }

        let workingDirectory: String = withUnsafePointer(to: &vnodeInfo.pvi_cdir.vip_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
                String(cString: $0)
            }
        }

        return workingDirectory
    }

    static func commandLine(for pid: PID) -> [String]? {
        var sysctlName = [CTL_KERN, KERN_PROCARGS2, Int32(pid)]

        var size = 0
        if sysctl(&sysctlName, UInt32(sysctlName.count), nil, &size, nil, 0) != 0 {
            print("Failed to get size of sysctl output buffer for process command")
            return nil
        }

        if size == 0 {
            return nil
        }

        var buffer = [CChar](repeating: 0, count: size)
        if sysctl(&sysctlName, UInt32(sysctlName.count), &buffer, &size, nil, 0) != 0 {
            perror("Failed to invoke sysctl to write to output buffer for process command")
            return nil
        }

        // todo(ethan): Idk how endianness works here.
        // I'm just gonna take the first byte and pray that there are less than 256 arguments.
        let argc = CUnsignedChar(bitPattern: buffer[0])

        guard argc > 0 else { return nil }

        return parseSysctlArguments(argc: argc, buffer: buffer)
    }

    private static func parseSysctlArguments(argc: CUnsignedChar, buffer: [CChar]) -> [String]? {
        var index = MemoryLayout<CInt>.size // skip past argc

        guard index < buffer.count else { return nil }

        var arguments: [String] = []
        for _ in 0 ..< argc {
            guard index < buffer.count else { break }
            let argumentStart = index

            if buffer[argumentStart] == 0 {
                index += 1
                continue
            }

            while index < buffer.count && buffer[index] != 0 {
                index += 1
            }
            guard let argument = buffer.withUnsafeBufferPointer({ ptr -> String? in
                if let base = ptr.baseAddress {
                    return String(cString: base.advanced(by: argumentStart))
                } else {
                    return nil
                }
            }) else {
                return nil
            }
            arguments.append(argument)
            index += 1
        }

        arguments.removeFirst()
        return arguments
    }
}

struct ProcessInfo: Identifiable, Equatable {
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        lhs.id == rhs.id
    }

    let id: PID
    let appNameAndConfig: (String, [String])?
    let workingDirectory: String?
    let command: [String]?
}

private func fetchProcesses() -> [ProcessInfo]? {
    guard let pids = SysctlHelper.getWine64PreloaderPids() else {
        return nil
    }

    var processes: [ProcessInfo] = []

    for id in pids {
        let workingDirectory = SysctlHelper.workingDirectory(for: id)
        let command = SysctlHelper.commandLine(for: id)
        let appNameAndConfig: (String, [String])? = command.flatMap {
            if $0.count <= 1 {
                return nil
            } else {
                return ($0[1], Array($0.suffix(from: 2)))
            }
        }
        let process = ProcessInfo(
            id: id,
            appNameAndConfig: appNameAndConfig,
            workingDirectory: workingDirectory,
            command: command
        )
        processes.append(process)
    }

    return processes
}

enum AppInfo {
    case app(String, PEFile?, [ProcessInfo])
    case anonymous(ProcessInfo)
}

extension AppInfo: Comparable {
    static func < (lhs: AppInfo, rhs: AppInfo) -> Bool {
        switch (lhs, rhs) {
        case (.app(let name1, _, _), .app(let name2, _, _)):
            return name1 < name2
        case (.anonymous(let process1), .anonymous(let process2)):
            return process1.id < process2.id
        case (.app, .anonymous):
            return true
        case (.anonymous, .app):
            return false
        }
    }
}

extension AppInfo: Identifiable {
    var id: String {
        switch self {
        case .app(let name, _, _):
            return name
        case .anonymous(let processInfo):
            return processInfo.id.description
        }
    }
}

struct AppInfoView: View {
    let appInfo: AppInfo
    @State var image: Image?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            switch appInfo {
            case .app(let name, let icon, let processInfos):
                CollapsibleView(header: {
                    HStack {
                        if let icon = image {
                            icon
                                .resizable()
                                .frame(width: 25, height: 25)
                        } else {
                            Image(systemName: "app.dashed")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                        Text(name)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }, content: {
                    ForEach(processInfos) { processInfo in
                        CollapsibleView(header:
                                            { Text("Process ID: \(processInfo.id)")
                            .font(.body)}
                                        , content: {
                            VStack {
                                if let workingDirectory = processInfo.workingDirectory {
                                    Text("Working Directory: \(workingDirectory)")
                                        .font(.body)
                                }

                                if let config = processInfo.appNameAndConfig?.1 {
                                    AppConfigView(config: config)
                                }
                            }
                        })
                    }
                })

            case .anonymous(let processInfo):
                CollapsibleView(header:
                                    {Text("Anonymous Wine Process")
                    .font(.title)}, content: {
                        CollapsibleView(header:
                                            {Text("Process ID: \(processInfo.id)")
                            .font(.body)}, content: {
                                VStack {
                                    if let workingDirectory = processInfo.workingDirectory {
                                        Text("Working Directory: \(workingDirectory)")
                                            .font(.body)
                                    }

                                    if let config = processInfo.appNameAndConfig?.1 {
                                        AppConfigView(config: config)
                                    }
                                }
                            })
                    })
            }
        }
        .task {
            switch appInfo {
            case .app(let string, let peFile, let array):
                guard let peFile = peFile else { return }
                let task = Task.detached {
                    guard let image = peFile.bestIcon() else { return nil as Image? }
                    return Image(nsImage: image)
                }
                self.image = await task.value
            default:
                break
            }
        }
        .padding()
    }
}

struct AppConfigView: View {
    let config: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(config, id: \.self) { flag in
                let flag = Array(flag.split(separator: "=", maxSplits: 2, omittingEmptySubsequences: false))
                let flagName = flag[0]
                let flagValue = flag.count == 1 ? "" : flag[1]

                HStack {
                    Text(flagName)
                        .font(.body)
                        .fontWeight(.semibold)
                    Text(flagValue)
                        .font(.body)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                Divider()
            }
        }
    }
}

@MainActor
class ProcessMonitor: ObservableObject {
    let prefixFilter: String
    let programs: [Program]
    @Published var processes: [ProcessInfo] = []
    @Published var organizedView: [AppInfo] = []
    // todo(ethan): can't get timer to work

    init(bottle: Bottle) {
        self.prefixFilter = bottle.url.path()
        self.programs = bottle.programs
        manualUpdate()
    }

    func manualUpdate() {
        Task.detached(priority: .userInitiated) {
            if let newProcesses = fetchProcesses() {
                await MainActor.run {
                    self.processes = newProcesses.filter { ($0.workingDirectory ?? "").starts(with: self.prefixFilter) }
                    self.organizeProcesses()
                }
            }
        }
    }

    func organizeProcesses() {
        var named = [String: [ProcessInfo]]()
        var unnamed = [ProcessInfo]()
        for process in processes {
            if let name = process.appNameAndConfig?.0 {
                if named[name] == nil {
                    named[name] = []
                }
                named[name]?.append(process)
            } else {
                unnamed.append(process)
            }
        }

        organizedView = []
        for named in named {
            organizedView.append(AppInfo.app(named.key, programs.first(where: {
                return $0.url.path().hasSuffix(
                    named.key.replacingOccurrences(of: "C:", with: "").replacingOccurrences(of: "\\", with: "/"))
            })?.peFile, named.value))
        }
        for unnamed in unnamed {
            organizedView.append(.anonymous(unnamed))
        }
        organizedView.sort()
    }
}

struct MonitorView: View {
    @StateObject private var monitor: ProcessMonitor

    init(bottle: Bottle) {
        _monitor = StateObject(wrappedValue: ProcessMonitor(bottle: bottle))
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("why.monitor")
            Button("Manual Debug Refresh") {
                monitor.manualUpdate()
            }
            ForEach(monitor.organizedView) { appInfo in
                AppInfoView(appInfo: appInfo)
            }
        }
        .padding()
    }
}
