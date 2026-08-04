//
//  MenuBarManager.swift
//  RepDesktopHelper
//
//  Created by alex haidar on 7/21/26.
//
/* Backend manager for accessing macOS process layor */
import Foundation
import AppKit
import Combine


final class MenuBarManager: ObservableObject {
    private init () {}
    
    static let shared = MenuBarManager()
    private var task: Task<Void, Never>?
   
//    func startOSProcessTask() {
//        task?.cancel()
//        
//        task = Task.detached(priority: .background) {
//            while !Task.isCancelled {
//                do {
//                    try await self.accessOSProcesses()
//                    //try await self.detectProviderWindow()
//                    
//                    print("getting processes...")
//                } catch {
//                    print("failed to start process listening loop", ErrorDesc.taskError)
//                }
//                try? await Task.sleep(for: .seconds(5))
//            }
//        }
//    }
    
//    
//    func accessOSProcesses() throws {
//        let workspace: [NSRunningApplication] = NSWorkspace.shared.runningApplications
//        guard !workspace.isEmpty else { throw ErrorDesc.noRunningProcessError }
//        
//        for app in workspace {
//            print("running process(s) bundle id: \(app.bundleIdentifier ?? "") | running process(s) name: \(app.localizedName ?? "") ")
//        }
//    }
    
//
//    func detectProviderWindow() async throws -> Bool {
//        guard let workspace: NSRunningApplication = NSWorkspace.shared.frontmostApplication else { return false }
//        let providerBundleId: Set<String> = ["us.zoom.xos", "com.microsoft.teams2","com.microsoft.teams", "Cisco-Systems.Spark", "com.cisco.webexmeetings",
//                                             "com.google.Chrome", "com.apple.Safari", "com.microsoft.edgemac", "company.thebrowser.Browser", "org.mozilla.firefox"]
//        
//        let browsers: Set<String> = ["com.google.Chrome", "com.apple.Safari", "com.microsoft.edgemac", "company.thebrowser.Browser", "org.mozilla.firefox"]
//        guard let appProvider: String = workspace.bundleIdentifier else { return false }
//        print("FRONTMOST APP:", workspace.localizedName ?? "nil", appProvider)
//
//        if browsers.contains(appProvider) {
//            let providerBrowserTitle: String = AccessWindows.frontmostWindowTitle(for: workspace)?.lowercased() ?? ""
//            
//            print("BROWSER TITLE:", providerBrowserTitle)
//            let providerAppTitle: Bool = providerBrowserTitle.contains("meet.google.com") || providerBrowserTitle.contains("google meet")
//                                                                                          || providerBrowserTitle.contains("zoom meeting")
//                                                                                          || providerBrowserTitle.contains("teams meeting")
//           
//            print("ACTIVE APP PROVIDER: \(providerAppTitle)")
//            return providerAppTitle
//        }
//        
//        guard providerBundleId.contains(appProvider) else { return false }
//        return true
//    }
}

