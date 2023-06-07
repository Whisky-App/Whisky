//
//  GPTInstallView.swift
//  Whisky
//
//  Created by Isaac Marovitz on 07/06/2023.
//

import SwiftUI

struct GPTInstallView: View {
    @State private var dragOver = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Drag and drop the Game Porting Toolkit DMG")
                .foregroundStyle(.secondary)
            Image(systemName: "plus.square.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80)
                .foregroundColor(dragOver ? .green : .white)
                .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                    providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url",
                                                            completionHandler: { (data, _) in
                        if let data = data,
                           let path = NSString(data: data, encoding: 4),
                           let url = URL(string: path as String) {
                            GPT.install(url: url)
                            dismiss()
                        }
                    })
                    return true
                }
                .animation(.easeInOut(duration: 0.2), value: dragOver)
        }
        .padding()
    }
}

struct GPTInstallView_Previews: PreviewProvider {
    static var previews: some View {
        GPTInstallView()
    }
}
