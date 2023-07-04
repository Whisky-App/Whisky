//
//  AppModel.swift
//  Whisky
//
//  Created by 朱拂 on 2023/7/4.
//

import Foundation

class AppModel: ObservableObject {
    @Published var showSetup: Bool = false {
        didSet {
            UserDefaults.standard.set(showSetup, forKey: "showSetup")
        }
    }
    @Published var bottlesLoaded: Bool = false
    init() {
        self.showSetup = UserDefaults.standard.bool(forKey: "showSetup")
    }
}
