//
//  BarBuddyWatchApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

@main
struct BarBuddyWatchApp: App {
    @StateObject private var drinkViewModel = WatchDrinkViewModel()
    @StateObject private var bacViewModel = WatchBACViewModel()
    @StateObject private var userViewModel = WatchUserViewModel()
    
    // For handling background refresh
    @WKApplicationDelegateAdaptor private var appDelegate: WatchAppDelegate
    
    // Handle complications
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchMainView()
                    .environmentObject(drinkViewModel)
                    .environmentObject(bacViewModel)
                    .environmentObject(userViewModel)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Refresh data when app becomes active
                Task {
                    await bacViewModel.refreshBAC()
                }
            }
        }
        
        WKNotificationScene(controller: NotificationController.self, category: "BAC_CATEGORY")
    }
}

// App delegate for handling background tasks
class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Schedule background refreshes
        scheduleBackgroundRefreshes()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refreshTask = task as? WKApplicationRefreshBackgroundTask {
                // Schedule the next background refresh
                scheduleBackgroundRefreshes()
                
                // Update complications
                #if os(watchOS)
                let server = CLKComplicationServer.sharedInstance()
                for complication in server.activeComplications ?? [] {
                    server.reloadTimeline(for: complication)
                }
                #endif
            }
            
            // Mark task complete
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    private func scheduleBackgroundRefreshes() {
        #if os(watchOS)
        let refreshDate = Date().addingTimeInterval(15 * 60) // Refresh every 15 minutes
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("Error scheduling background refresh: \(error)")
            }
        }
        #endif
    }
}

// Controller for handling notification interfaces
class NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView {
        return NotificationView()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    override func didReceive(_ notification: UNNotification) {
        // Extract notification content here if needed
    }
}
