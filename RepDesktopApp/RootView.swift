//
//  RootView.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/14/26.
//
import Foundation
import SwiftUI


struct RootView: View {
    @StateObject private var auth = AuthBackend()

    var body: some View {
        Group {
            if auth.isSignedIn {
                ContentView()
            } else {
                AuthView()
            }
        }
        .task {
            await auth.loadSession()
        }
    }
}
