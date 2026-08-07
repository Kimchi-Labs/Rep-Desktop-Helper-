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


//public final class AuthenticatePairing {
//    public static func desktopAuthPoller() async throws -> String {
//        
//        let supabasePublicAnon: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im94Z3Vtd3F4bmdocWNjYXp6cXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MTE0MjQsImV4cCI6MjA2Mjk4NzQyNH0.gt_S5p_sGgAEN1fJSPYIKEpDMMvo3PNx-pnhlC_2fKQ"
//        
//        var urlRequest: URLRequest = URLRequest(url: URL(string: "https://oxgumwqxnghqccazzqvw.supabase.co/functions/v1/rep_desktop_pairing")!)
//        urlRequest.httpMethod = "GET"
//        urlRequest.setValue(supabasePublicAnon, forHTTPHeaderField: "apikey")
//        urlRequest.setValue("Bearer \(supabasePublicAnon)", forHTTPHeaderField: "Authorization")
//        
//        let (data, response) = try await URLSession.shared.data(for: urlRequest)
//        guard let resp = response as? HTTPURLResponse, resp.statusCode == 200 else { throw ErrorDesc.urlResponseError }
//        
//        let decoder = JSONDecoder()
//        let decodeResponse = try decoder.decode(DesktopPairing.self, from: data)
//        
//        let userId: String = decodeResponse.user_id ?? "user id empty"
//        let desktopAccessToken: String = decodeResponse.desktop_access_token ?? "empty token"
//        
//        print("TOKEN: \(desktopAccessToken) | USER ID: \(userId)")
//        return desktopAccessToken
//    }
//}


public final class ScreenAudio: NSObject, SCStreamOutput {
    
    static let screenAudio = ScreenAudio()
    private static let queue = DispatchQueue(label: "rep.desktop.helper", qos: .userInitiated)
    public static var stream: SCStream?
    
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        print("got screen/system audio buffer")
        
        Task {
            do {
                let _ = try await AudioTranscriptionManager.shared.startSystemCapture(from: sampleBuffer)
                
                print("system audio input called")
            } catch {
                print("failed to created pcm audio buffers", ErrorDesc.audioError, error)
            }
        }
    }
    
    
    public static func configScreenAudioCapture() async throws {
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
            return "Audio Meeting"
        }
    }
}
