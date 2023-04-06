//
//  ProgramView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 31/03/2023.
//

import SwiftUI
import QuickLookThumbnailing

struct ProgramView: View {
    @Binding var program: Program
    @State var image: NSImage?

    var body: some View {
        VStack {
            Form {
                Section("info.title") {
                    HStack {
                        InfoItem(label: NSLocalizedString("info.path", comment: ""), value: program.url.path)
                        .contextMenu {
                            Button {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(program.url.path, forType: .string)
                            } label: {
                                Text("info.path.copy")
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            Spacer()
        }
        .navigationTitle(program.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Group {
                    if let icon = image {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 25, height: 25)
                    } else {
                        Image(systemName: "app.dashed")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }
                }
                .padding(.trailing, 5)
            }
        }
        .onAppear {
            let thumbnail = QLThumbnailGenerator.Request(fileAt: program.url,
                                                         size: CGSize(width: 512, height: 512),
                                                         scale: 1,
                                                         representationTypes: .thumbnail)

            QLThumbnailGenerator.shared.generateBestRepresentation(for: thumbnail) { rep, _ in
                if let rep = rep {
                    image = rep.nsImage
                }
            }
        }
    }
}
