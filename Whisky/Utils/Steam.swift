//
//  Steam.swift
//  Whisky
//
//  Created by Isaac Marovitz on 14/06/2023.
//

import Foundation

class Steam {
    static func registryChanges(bottle: Bottle) async throws {
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\AppDefaults\prey.exe\OpenGL"#,
                                     name: "DisabledExtensions", data: "GL_ATI_text_fragment_shader", type: .string)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\AppDefaults\hl2.exe\Direct3D"#,
                                     name: "pow_abs", data: "disabled", type: .string)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\Fonts\Replacements"#,
                                     name: "Lucida Console", data: "MS Sans Serif", type: .string)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\AppDefaults\steam.exe\DllOverrides"#,
                                     name: "wineoss.drv", data: "d", type: .string)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Valve\Steam"#,
                                     name: "GPUAccelWebViews", data: "0", type: .dword)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\AppDefaults\steamwebhelper.exe"#,
                                     name: "LargeAddressAware", data: "1", type: .dword)
        try await Wine.addRegistyKey(bottle: bottle, key: #"HKCU\Software\Wine\Fonts\Replacements"#,
                                     name: "Meiryo", data: "Microsoft YaHei", type: .string)
    }
}
