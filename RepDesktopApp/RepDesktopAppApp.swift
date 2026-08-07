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
    @StateObject private var meetingDetection = MenuBarManager.shared
    @StateObject private var audioManager = AudioTranscriptionManager.shared
    
    
    private let notificationDelegate = LocalNotificationsDelegate.shared
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }
    
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
            
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
        
        RepMenuBar().environmentObject(meetingDetection)
        
    }
}

