//
//  GlobalHelpers.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/11/26.
//
import Foundation
import AppKit
import ApplicationServices
import ScreenCaptureKit
import CoreMedia



public final class ScreenAudio: NSObject, SCStreamOutput {
    
    static let screenAudio = ScreenAudio()
    private static let queue = DispatchQueue(label: "rep.desktop.helper", qos: .userInitiated)
    private var webSocketTask: URLSessionWebSocketTask?
    public static var stream: SCStream?
    private let system = SystemAudioTranscriptionManager()
    
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, let webSocketTask else { return }
        print("got screen/system audio buffer")
        
        Task {
            do {
                let _ = try await system.startSystemCapture(from: sampleBuffer, webSocketTask: webSocketTask)
                
                print("system audio input called")
            } catch {
                print("failed to created pcm audio buffers", ErrorDesc.audioError, error)
            }
        }
    }
    
    
    public static func configScreenAudioCapture(webSocketTask: URLSessionWebSocketTask) async throws {
        screenAudio.webSocketTask = webSocketTask

        let config = SCStreamConfiguration()
       
        config.sampleRate = 24_000
        config.channelCount = 1
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true    ///prevents audio echo
        
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else { throw ErrorDesc.screenCaptureConfigError }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
      
        
        do {
            self.stream = SCStream(filter: filter, configuration: config, delegate: nil)
            try stream?.addStreamOutput(screenAudio, type: .audio, sampleHandlerQueue: queue)
            try await stream?.startCapture()
            
            print("audio stream output for screen capture added")
        } catch {
            print("failed to get audio screen capture output", ErrorDesc.audioError, error)
        }
    }


    public static func clearCaptureSocket() {
        screenAudio.webSocketTask = nil
    }
}


public final class Accessibility {
    public static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}


public final class DisplayProvider {
    public static func displayProvider(appProvider: String) -> String {
        
        switch appProvider {
        case "us.zoom.xos":
            return "Zoom"
        case "com.microsoft.teams2":
            return "Teams"
        case "com.microsoft.teams":
            return "Teams"
        case "Cisco-Systems.Spark":
            return "Webex"
        case "com.cisco.webexmeetings":
            return "Webex"
        case "com.google.Chrome":
            return "Google Meets"
        case "com.hnc.Discord":
            return "Discord"
        default:
            return "System Audio"
        }
    }
}
