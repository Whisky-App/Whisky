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
import SwiftUI

struct ProcessInfo: Identifiable {
    let id: Int
    let name: String
    let message: String
}

private func fetchProcesses() -> [ProcessInfo]? {
    var processes: [ProcessInfo] = []

    // sysctl my beloved
    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
    var size = 0

    let sysctlForSizeResult = sysctl(&name, UInt32(name.count), nil, &size, nil, 0)
    if sysctlForSizeResult != 0 {
        print("Error getting size of process list")
        return nil
    }

    let processCount = size / MemoryLayout<kinfo_proc>.stride
    let processListStart = UnsafeMutablePointer<kinfo_proc>.allocate(capacity: processCount)
    defer { processListStart.deallocate() }

    let sysctlForListResult = sysctl(&name, UInt32(name.count), processListStart, &size, nil, 0)
    if sysctlForListResult != 0 {
        print("Error getting process list")
        return nil
    }

    let processList = UnsafeBufferPointer(start: processListStart, count: processCount)

    for rawProcessInfo in processList {
        let comm = withUnsafePointer(to: rawProcessInfo.kp_proc.p_comm) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                String(cString: $0)
            }
        }

        if comm == "wine64-preloader" {
            let id = Int(rawProcessInfo.kp_proc.p_pid)

            let message = withUnsafePointer(to: rawProcessInfo.kp_proc.p_wmesg) {
                $0.withMemoryRebound(to: CChar.self, capacity: Int(100)) {
                    String(cString: $0)
                }
            }

            processes.append(ProcessInfo(id: id, name: comm, message: message))
        }
    }

    return processes
}

@MainActor
class ProcessMonitor: ObservableObject {
    @Published var processes: [ProcessInfo] = []

//    private var timer: DispatchSourceTimer?
//    private let timerQueue = DispatchQueue(label: "processmonitor", attributes: .concurrent)

    init() {
        manualUpdate()
    }

    func startFetching() {
//        if timer != nil { return }
//
//        timer = DispatchSource.makeTimerSource(queue: timerQueue)
//        timer?.schedule(deadline: .now(), repeating: 5.0)
//        timer?.setEventHandler {
//            if let newProcesses = fetchProcesses() {
//                print(newProcesses)
//            }
//        }
//        timer?.resume()
    }

    // Stop the timer
    func stopFetching() {
//        print("stopFetching")
//        timer?.cancel()
//        timer = nil
    }

    func manualUpdate() {
        Task.detached(priority: .userInitiated) {
            if let newProcesses = fetchProcesses() {
                await MainActor.run {
                    self.processes = newProcesses
                }
            }
        }
    }

    deinit {
//        timer?.cancel()
    }
}

struct MonitorView: View {
    @StateObject private var monitor = ProcessMonitor()

    var body: some View {
        VStack(alignment: .leading) {
            Text("why.monitor")
            List(monitor.processes) { process in
                HStack {
                    Text(process.id.description)
                        .frame(width: 100, alignment: .leading)
                        .selectionDisabled(false)
                    Text(process.name)
                        .selectionDisabled(false)
                }
                .selectionDisabled(false)
            }
            .selectionDisabled(false)
        }
        .selectionDisabled(false)
        .padding()
        .bottomBar {
            HStack {
                Spacer()
                Button("button.refresh") {
                    monitor.manualUpdate()
                }
            }
            .padding()
        }
//        .onAppear {
//            print("onAppear")
//            monitor.startFetching()
//        }
//        .onDisappear {
//            print("onDisappear")
//            monitor.stopFetching()
//        }
    }
}

#Preview {
    MonitorView()
}
