//
//  MenuBarManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/21/26.
//
/* Backend manager for accessing macOS process
   layor and handling provider meeting detection */
import Foundation
import AppKit
import Combine
import OSLog


final class MenuBarManager: ObservableObject {
    private init () {}
    
    static let shared = MenuBarManager()
    private var task: Task<Void, Never>?
    
    let logger = Logger(subsystem: "kimchilabs.rep.RepDesktopApp", category: "ProviderDetection")
   
    func startOSProcessTask() {
        task?.cancel()
        
        task = Task.detached(priority: .background) {
            while !Task.isCancelled {
                do {
                    try await self.accessOSProcesses()
                    let _ = try await self.detectProviderWindow()
                    
                    print("getting processes...")
                } catch {
                    print("failed to start process listening loop", ErrorDesc.taskError)
                }
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    
    func accessOSProcesses() throws {
        let workspace: [NSRunningApplication] = NSWorkspace.shared.runningApplications
        guard !workspace.isEmpty else { throw ErrorDesc.noRunningProcessError }
        
        for app in workspace {
            print("running process(s) bundle id: \(app.bundleIdentifier ?? "") | running process(s) name: \(app.localizedName ?? "") ")
        }
    }
    

    func detectProviderWindow() async throws -> Bool {
        guard let workspace: NSRunningApplication = NSWorkspace.shared.frontmostApplication else { return false }
        let providerBundleId: Set<String> = ["us.zoom.xos", "com.microsoft.teams2","com.microsoft.teams", "Cisco-Systems.Spark", "com.cisco.webexmeetings",
                                             "com.google.Chrome", "com.apple.Safari", "com.microsoft.edgemac", "company.thebrowser.Browser", "org.mozilla.firefox", "com.hnc.Discord"]
    
        guard let appProvider: String = workspace.bundleIdentifier else { return false }
        logger.info("APP PROVIDER BUNDLE ID: \(appProvider)")
    
        guard providerBundleId.contains(appProvider) else { return false }
        return true
    }
}

