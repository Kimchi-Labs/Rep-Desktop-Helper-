//
//  RootView.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/14/26.
//
import Foundation
import SwiftUI


struct RootView: View {
    @StateObject private var auth = AuthBackend.shared

    var body: some View {
        Group {
            if auth.isShowingSignIn && !auth.isSignedIn {
                AuthView(auth: auth)
            } else {
                ContentView()
            }
        }
        .task {
            await auth.loadSession()
        }
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents()
    }
}
