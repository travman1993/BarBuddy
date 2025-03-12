//
//  BarBuddyApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

@main
struct BarBuddyApp: App {
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var drinkViewModel = DrinkViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var bacViewModel = BACViewModel()
    @StateObject private var emergencyViewModel = EmergencyViewModel()
    
    // Services
    private let notificationService = NotificationService()
    
    // Track app state for analytics and lifecycle management
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set up app appearance
        configureAppAppearance()
        
        // Set up notifications
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
                .environmentObject(drinkViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(bacViewModel)
                .environmentObject(emergencyViewModel)
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Setup Methods
    
    private func configureAppAppearance() {
        // Configure global appearance for UIKit elements
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Track app launch
        incrementLaunchCount()
    }
    
    private func setupNotifications() {
        Task {
            // Request notification permissions
            let granted = await notificationService.requestPermissions()
            
            // Set up notification categories
            if granted {
                notificationService.setUpNotificationCategories()
            }
        }
    }
    
    // MARK: - App Lifecycle Handling
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            Analytics.shared.logEvent(.appOpened)
            updateLastActiveTime()
            
            // Refresh BAC calculations when app becomes active
            Task {
                await bacViewModel.calculateBAC()
            }
            
        case .inactive:
            // App going to inactive state
            updateLastActiveTime()
            
        case .background:
            // App going to background
            updateLastActiveTime()
            
            // Schedule any necessary notifications
            if bacViewModel.currentBAC.bac > 0 {
                notificationService.scheduleBACSoberNotification(estimate: bacViewModel.currentBAC)
                notificationService.scheduleInactivityCheckIn(lastActiveTime: Date())
            }
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateLastActiveTime() {
        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.lastActiveDate)
    }
    
    private func incrementLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: Constants.UserDefaultsKeys.launchCount)
        UserDefaults.standard.set(currentCount + 1, forKey: Constants.UserDefaultsKeys.launchCount)
        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.lastLaunchDate)
    }
}

struct ContentView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        Group {
            if userViewModel.isFirstLaunch {
                OnboardingView()
            } else if !userViewModel.hasAcceptedDisclaimer {
                DisclaimerView()
            } else {
                MainTabView()
            }
        }
    }
}
