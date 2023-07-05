//
//  GPTKInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 20/06/2023.
//

import SwiftUI

struct GPTKInstallView: View {
    @State private var dragOver = false
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack {
            Text("setup.gptk")
                .font(.title)
                .fontWeight(.bold)
            Text("gptkalert.init")
                .foregroundStyle(.secondary)
            Spacer()
            if model.gptkInstalling {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 80)
            } else {
                Image(systemName: "plus.square.dashed")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(dragOver ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: dragOver)
            }
            Spacer()
        }
        .frame(width: 400, height: 200)
        .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url",
                                                    completionHandler: { (data, _) in
                if let data = data,
                   let path = NSString(data: data, encoding: 4),
                   let url = URL(string: path as String) {
                    if url.pathExtension == "dmg" {
                        model.gptkLocation = url
                    } else {
                        print("Not a DMG!")
                    }
                }
            })
            return true
        }
    }
}
