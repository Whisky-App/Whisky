//
//  RunningProcessView.swift
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

import SwiftUI
import WhiskyKit

struct BottleProcess: Identifiable {
    var id = UUID()
    var pid: String
    var procName: String
}

struct RunningProcessesView: View {
    @ObservedObject var bottle: Bottle

    @State private var processes = [BottleProcess]()
    @State private var processSortOrder = [KeyPathComparator(\BottleProcess.pid)]
    @State private var selectedProcess: BottleProcess.ID?

    var body: some View {
        ZStack {
            if !processes.isEmpty {
                VStack {
                    Table(processes, selection: $selectedProcess, sortOrder: $processSortOrder) {
                        TableColumn("process.table.pid", value: \.pid)
                        TableColumn("process.table.executable", value: \.procName)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack {
                        Spacer()
                        Button("process.table.refresh") {
                            Task.detached(priority: .userInitiated) {
                                await fetchProcesses()
                            }
                        }
                        Button("process.table.kill") {
                            Task.detached(priority: .userInitiated) {
                                await killProcess()
                            }
                        }
                    }
                    .padding()
                }
            } else {
                HStack(alignment: .center) {
                    Spacer()
                    VStack(alignment: .center) {
                        ProgressView()
                            .padding()
                        Text("process.table.loading")
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            Task.detached(priority: .userInitiated) {
                await fetchProcesses()
            }
        }
    }

    func fetchProcesses() async {
        var newProcessList = [BottleProcess]()
        let output: String?

        do {
            output = try await Wine.runWine(["tasklist.exe"], bottle: bottle)
        } catch {
            print("Error running tasklist.exe: \(error)")
            output = ""
        }

        let lines = output?.split(omittingEmptySubsequences: true, whereSeparator: \.isNewline)
        for line in lines ?? [] {
            let lineParts = line.split(separator: ",", omittingEmptySubsequences: true)
            if lineParts.count > 1 {
                let pid = String(lineParts[1])
                let procName = String(lineParts[0])
                newProcessList.append(BottleProcess(pid: pid, procName: procName))
            }
        }
        processes = newProcessList
    }

    func killProcess() async {
        if let thisProcess = processes.first(where: { $0.id == selectedProcess }) {
            do {
                try await Wine.runWine(["taskkill.exe", "/PID", thisProcess.pid, "/F"], bottle: bottle)
                try await Task.sleep(nanoseconds: 2000)
            } catch {
                print("Error running taskkill.exe: \(error)")
            }
            await fetchProcesses()
        }
    }
}
