//
//  WindowConfigurator.swift
//  RepDesktopApp
//
//  Created by alex haidar on 7/4/26.
/* base UI layor to make macOS window translucent */
import AppKit
import SwiftUI


struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            guard let window = view.window else { return }

            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.remove(.titled)
            window.styleMask.insert(.borderless)
            window.isMovableByWindowBackground = true

            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = .normal
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
