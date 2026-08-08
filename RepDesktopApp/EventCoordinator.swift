//
//  EventCoordinator.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 8/8/26.
//
/* Manages desktop UI activation audio transcription and
   permission requests for meeting auto-detect events */
import Foundation
import AppKit


final class AppCoordinator {
    private init() {}
    
    static let shared = AppCoordinator()
    let audioManager = AudioTranscriptionManager.shared
    
    
    func openDesktop() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            window.level = .modalPanel
        }
    }
    
    
    func quitDesktop() {
        NSApplication.shared.terminate(nil)
    }
    
    
    func requestAudioAccess() {
       let access = Accessibility.requestAccessibilityPermission()
        print("is permission granted?: \(access)")
    }
    
    
    @MainActor
    func transcribe() async throws {
        guard !audioManager.isTranscribing else { return }
        
        audioManager.isRecording = true
        audioManager.isPaused = false
        try await AudioTranscriptionHelper.requestMicAccess()
        let session = try await audioManager.openAudioSession()
        try await audioManager.startAudioStream(session: session)
        
        let isToggled = UserDefaults.standard.object(forKey: "isToggled") as? Bool ?? true
        if isToggled {
            try await LocalNotificationsDelegate.shared.meetingDetected()
        }
    }
}
