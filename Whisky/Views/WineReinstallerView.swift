//
//  WineReinstallerView.swift
//  Whisky
//
//  Created by Venti on 15/06/2023.
//

import SwiftUI

struct WineReinstallerView: View {
    @Binding var isPresented: Bool

    @State var useBuiltInWine: Bool = true
    @State var customWinePath: String = ""
    @State var isWorking = false

    var body: some View {
        VStack {
            Text("wine.reinstall")
                .font(.title)
                .padding()
            VStack {
                Toggle(isOn: $useBuiltInWine, label: {
                    Text("wine.reinstall.useBuiltIn")
                })
                if !useBuiltInWine {
                    HStack {
                        TextField("", text: $customWinePath)
                            .textFieldStyle(.roundedBorder)
                            .disabled(useBuiltInWine)
                        Button {
                            let wineArchiveBrowser = NSOpenPanel()
                            wineArchiveBrowser.canChooseFiles = true
                            wineArchiveBrowser.canChooseDirectories = false
                            wineArchiveBrowser.allowsMultipleSelection = false
                            wineArchiveBrowser.allowedContentTypes = [.zip]
                            wineArchiveBrowser.begin { response in
                                if response == .OK {
                                    if let result = wineArchiveBrowser.url {
                                        customWinePath = result.absoluteString
                                    }
                                }
                            }
                        } label: {
                            Text("button.browse")
                        }
                    }
                }
            }
            .padding()

            if isWorking {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }

            HStack {
                Button {
                    isPresented.toggle()
                } label: {
                    Text("button.cancel")
                }
                Button {
                    isWorking = true
                    Task.detached {
                        if useBuiltInWine {
                            WineInstaller.installWine()
                        } else {
                            if let url = URL(string: customWinePath) {
                                WineInstaller.installWine(archivePath: url)
                            }
                        }
                        Task { @MainActor in
                            isWorking = false
                            // Since triggering GPTInstallView isn't quite an option here yet.
                            // ...quit the app
                            let alert = NSAlert()
                            alert.messageText = String(localized: "alert.reinstall")
                            alert.informativeText = String(localized: "alert.reinstall.message")
                            alert.alertStyle = .informational
                            alert.addButton(withTitle: String(localized: "button.ok"))
                            if alert.runModal() == .alertFirstButtonReturn {
                                exit(0)
                            }
                        }
                    }
                } label: {
                    Text("button.ok")
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
        .disabled(isWorking)
    }
}

struct WineReinstallerView_Previews: PreviewProvider {
    static var previews: some View {
        WineReinstallerView(isPresented: Binding.constant(true))
    }
}
