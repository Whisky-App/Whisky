//
//  PinView.swift
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

struct PinView: View {
    @ObservedObject var bottle: Bottle
    @ObservedObject var program: Program
    @State var pin: PinnedProgram
    @Binding var path: NavigationPath

    @State private var image: Image?
    @State private var showRenameSheet = false
    @State private var name: String = ""
    @State private var opening: Bool = false

    var body: some View {
        VStack {
            Group {
                if let image = image {
                    image
                        .resizable()
                } else {
                    Image(systemName: "app.dashed")
                        .resizable()
                }
            }
            .frame(width: 45, height: 45)
            .scaleEffect(opening ? 2 : 1)
            .opacity(opening ? 0 : 1)
            Spacer()
            Text(name)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(width: 90, height: 90)
        .padding(10)
        .overlay {
            HStack {
                Spacer()
                Image(systemName: "play.fill")
                    .resizable()
                    .foregroundColor(.green)
                    .frame(width: 16, height: 16)
            }
            .frame(width: 45, height: 45)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
        }
        .contextMenu {
            ProgramMenuView(program: program, path: $path)

            Button("button.rename", systemImage: "pencil.line") {
                showRenameSheet.toggle()
            }
            .labelStyle(.titleAndIcon)
            Button("button.showInFinder", systemImage: "folder") {
                NSWorkspace.shared.activateFileViewerSelecting([program.url])
            }
            .labelStyle(.titleAndIcon)
        }
        .onTapGesture(count: 2) {
            runProgram()
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameView("rename.pin.title", name: name) { newName in
                name = newName
            }
        }
        .task {
            name = pin.name
            guard let peFile = program.peFile else { return }
            let task = Task.detached {
                guard let image = peFile.bestIcon() else { return nil as Image? }
                return Image(nsImage: image)
            }
            self.image = await task.value
        }
        .onChange(of: name) {
            if let index = bottle.settings.pins.firstIndex(where: {
                let exists = FileManager.default.fileExists(atPath: pin.url?.path(percentEncoded: false) ?? "")
                return $0.url == pin.url && exists
            }) {
                bottle.settings.pins[index].name = name
            }
        }
    }

    func runProgram() {
        withAnimation(.easeIn(duration: 0.25)) {
            opening = true
        } completion: {
            withAnimation(.easeOut(duration: 0.1)) {
                opening = false
            }
        }

        program.run()
    }
}
