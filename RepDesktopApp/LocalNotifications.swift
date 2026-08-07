//
//  LocalNotifications.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/19/26.
//
import UserNotifications


final class LocalNotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LocalNotificationsDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
    
    func requestLocalNotificationPermission() async throws {
        let center = UNUserNotificationCenter.current()
        
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { throw ErrorDesc.permissionsError }
        
        print("local notification permission granted")
    }
    
    func notifyNotesSentToMobile() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Notes sent to Rep"
        content.body = "Open Rep on your iPhone to see your notes and start using LiveActivity flashcards"
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(identifier: "desktop-notes-sent-\(UUID().uuidString)", content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
    
    func meetingDetected() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Meeting Detected"
        content.body = "Rep is Auto transcribing this meeting"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "desktop-meeting-detected\(UUID().uuidString)", content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
