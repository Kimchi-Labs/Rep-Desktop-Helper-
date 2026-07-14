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

    private let phases: [Double] = [0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18, 0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65,
                                    0.18, 0.18, 0.65, 0.75, 1.08, 1.12, 1.08, 0.75, 0.65, 0.18]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.15, paused: !isRecording || isPaused || audioLevel <= 0.03)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isActive = isRecording && !isPaused && audioLevel > 0.03
            let curve = isActive ? 0.85 : 0.0

            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<27, id: \.self) { index in
                    let phase = phases[index]
                    let sine = sin((time * 4.8) + (phase * .pi * 2))
                    let normalized = (sine + 1) / 2
                    let idleHeight = 21.0
                    let height = isActive ? idleHeight + normalized * 24.0 * curve : idleHeight

                    Capsule()
                        .frame(width: 5, height: height)
                        .foregroundStyle(Color.kimchilabsReversed)
                }
            }
            .frame(height: 42, alignment: .center)
        }
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


#Preview {
    Waveform(audioLevel: 3.0, isRecording: true, isPaused: false)
}

#Preview {
    AuthView()
}
