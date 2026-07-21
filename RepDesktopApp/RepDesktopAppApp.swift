//
//  RepDesktopAppApp.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
//

import SwiftUI
import UserNotifications



@main
struct RepDesktopAppApp: App {
    
    private let notificationDelegate = LocalNotificationsDelegate.shared
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
            
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
        
        RepMenuBar()
    }
}

