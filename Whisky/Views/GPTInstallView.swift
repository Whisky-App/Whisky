//
//  GPTInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import SwiftUI

struct GPTInstallView: View {
    @State private var dragOver = false
    @State private var installing = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("gptalert.init")
                .foregroundStyle(.secondary)
            if installing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 80)
            } else {
                Image(systemName: "plus.square.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
                    .foregroundColor(dragOver ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: dragOver)
            }
        }
        .fixedSize()
        .padding()
        .interactiveDismissDisabled()
        .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url",
                                                    completionHandler: { (data, _) in
                if let data = data,
                   let path = NSString(data: data, encoding: 4),
                   let url = URL(string: path as String) {
                    if url.pathExtension == "dmg" {
                        installing = true
                        GPT.install(url: url)
                        dismiss()
                    } else {
                        print("Not a DMG!")
                    }
                }
            })
            return true
        }
    }
}

struct GPTInstallView_Previews: PreviewProvider {
    static var previews: some View {
        GPTInstallView()
    }
}
