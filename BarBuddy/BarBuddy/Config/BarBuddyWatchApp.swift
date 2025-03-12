//
//  BarBuddyWatchApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// BarBuddyWatchApp.swift - Update to fix potential issues
import SwiftUI
import WatchKit

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
        
        #if os(watchOS)
        WKNotificationScene(controller: NotificationController.self, category: "BAC_CATEGORY")
        #endif
    }
}
