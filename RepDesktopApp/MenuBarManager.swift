//
//  MenuBarManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/21/26.
//
/* Backend manager for accessing macOS process layor,
  acting as an event listener, and calling provider APIs */
import Foundation
import AppKit
import Combine


final class MenuBarManager: ObservableObject {
    private init () {}
    
    static let shared = MenuBarManager()
    private var task: Task<Void, Never>?
   
    func startOSProcessTask() {
        task?.cancel()
        
        task = Task.detached(priority: .background) {
            while !Task.isCancelled {
                do {
                    try await self.accessOSProcesses()
                    
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
}

