//
//  UIComponents.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
//
import SwiftUI
import Foundation
import AuthenticationServices
import CryptoKit
import AppKit
import Combine



struct Waveform: View {
    let audioLevel: Double
    let isRecording: Bool
    let isPaused: Bool
    
    private let phases: [Double] = [0.42, 0.50, 0.61, 0.70, 0.78, 0.85, 0.80,
                                    0.72, 0.63, 0.58, 0.66, 0.75, 0.86, 0.94,
                                    1.00, 0.92, 0.84, 0.77, 0.82, 0.88, 0.79,
                                    0.68, 0.57, 0.49, 0.54, 0.63, 0.72]
    
    var body: some View {
        let isActive = isRecording && !isPaused && audioLevel > 0.03
        
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<27, id: \.self) { index in
                let height = isActive ? AudioTranscriptionHelper.waveHeight(for: index, audioLevel: audioLevel) : CGFloat(10)
                
                Capsule()
                    .frame(width: 5, height: height)
                    .foregroundStyle(Color.kimchilabsReversed)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 22), value: audioLevel)
            }
        }
        .frame(height: 42, alignment: .center)
    }
}


struct AuthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentNonce: String?
    @StateObject private var auth = AuthBackend()
    
    var body: some View {
        
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.clear)
                    .frame(width: 500, height: 180)
                    .glassEffect(.regular, in: .rect(cornerRadius: 30))
                
                VStack(alignment: .center, spacing: 5) {
                    Text("Sign Into Rep Desktop").foregroundStyle(Color.kimchilabsReversed)
                        .fontDesign(.default)
                        .fontWeight(.medium)
                    
                    Text("Capture meeting notes on your Mac\nand turn them appear on your iPhone as flashcards").font(.system(size: 12, design: .rounded)).fontWeight(.regular).opacity(0.5)
                        .multilineTextAlignment(.center)
                    
                    
                    Group {
                        switch colorScheme {
                        case .light:
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    auth.handleSuccessfulLogin(authorization, nonce: currentNonce)
                                    
                                case .failure(let error):
                                    auth.handleLoginError(with: error)
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            
                        case .dark:
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    auth.handleSuccessfulLogin(authorization, nonce: currentNonce)
                                    
                                case .failure(let error):
                                    auth.handleLoginError(with: error)
                                }
                            }
                            .signInWithAppleButtonStyle(.white)
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 190, height: 35)
                    .clipShape(RoundedRectangle(cornerRadius: 33, style: .continuous))
                }
            }
            
        }.frame(width: 500, height: 180)
            .background(WindowConfigurator())
            .background(Color.kimchilabsBackground)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

struct RepMenuBar: Scene {
    @State var isToggled: Bool = true
    @State var isRecording: Bool = false
    @State var isPaused: Bool = false
    
    var body: some Scene {
        
        MenuBarExtra("Rep", image: "repMenuBarIcon") {
            MenuBarView(isToggled: $isToggled, isRecording: $isRecording, isPaused: $isPaused)
        }.menuBarExtraStyle(.window)
    }
}


struct MenuBarView: View {
    @Binding var isToggled: Bool
    @Binding var isRecording: Bool
    @Binding var isPaused: Bool
    
    @StateObject var audioManager = AudioTranscriptionManager.shared
    
    func openDesktop() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }
    
    func quitDesktop() {
        NSApplication.shared.terminate(nil)
    }
    
    @MainActor
    func transcribe() async throws {
        isRecording = true
        isPaused = false
        try await AudioTranscriptionHelper.requestMicAccess()
        let session = try await audioManager.openAudioSession()
        try await audioManager.startAudioStream(session: session)
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 10) {
            
            HStack(spacing: 55) {
                Text("Enable auto detect").foregroundStyle(Color.kimchilabsReversed).opacity(0.8)
                    .font(.system(size: 12))
                    .fontDesign(.rounded)
                Toggle("", isOn: $isToggled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            
            Divider().padding(.horizontal)
            
            HStack {
                Button {
                    quitDesktop()
                } label: {
                    ZStack {
                        Capsule().frame(height: 20)
                            .foregroundStyle(Color.clear)
                        
                        HStack(spacing: 60) {
                            Text("Quit Rep Desktop helper")
                                .foregroundStyle(Color.kimchilabsReversed).opacity(0.8)
                                .font(.system(size: 12))
                                .fontDesign(.rounded)
                            
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(Color.kimchilabsReversed).opacity(0.8)
                                .font(.system(size: 14))
                        }
                    }
                }.buttonStyle(.plain)
            }.padding(.horizontal)
            
            Divider().padding(.horizontal)
            
            Text("Keep Rep in the menu bar to auto\ndetect and join meetings")
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.kimchilabsReversed).opacity(0.5)
                .multilineTextAlignment(.center)
            
            
            Button {
                openDesktop()
                Task {
                    try await transcribe()
                }
            } label: {
                ZStack {
                    Capsule().frame(height: 35).padding(.horizontal)
                        .foregroundStyle(Color.kimchilabsReversed)
                    
                    HStack(spacing: 5) {
                        Text("Start New Transcription")
                            .font(.system(size: 12, design: .rounded)).fontWeight(.regular)
                            .foregroundStyle(Color.kimchilabsBackground)
                        
                        Image(systemName: "waveform.mid")
                            .font(.system(size: 12, design: .rounded)).fontWeight(.regular)
                            .foregroundStyle(Color.kimchilabsBackground)
                    }
                }
                
            }.buttonStyle(.plain)
            
        }.frame(width: 250, height: 180)
    }
}

#Preview {
    Waveform(audioLevel: 3.0, isRecording: true, isPaused: false)
}

#Preview {
    AuthView()
}

#Preview {
    MenuBarView(isToggled: .constant(true), isRecording: .constant(false), isPaused: .constant(false))
}
