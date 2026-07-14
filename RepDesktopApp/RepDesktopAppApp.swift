//
//  RepDesktopAppApp.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
//

import SwiftUI

@main
struct RepDesktopAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
              
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
    }
}
