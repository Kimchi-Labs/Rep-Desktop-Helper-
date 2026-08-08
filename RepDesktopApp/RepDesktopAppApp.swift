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
    
    private let notificationDelegate = LocalNotificationsDelegate.shared
    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        let meeting = MenuBarManager.shared
        meeting.startOSProcessTask()
        Task {
            await meeting.runProviderDetectionLoop()
        }
    }
    
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
            
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
        
        RepMenuBar().environmentObject(meetingDetection)
        
    }
}

