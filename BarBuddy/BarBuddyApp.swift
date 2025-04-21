//
//  BarBuddyApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
import SwiftUI
import StoreKit
import Combine

@main
struct BarBuddyApp: App {
    // Keep existing state and observers
    @StateObject private var drinkTracker = DrinkTracker()
    
    // Use AppStorage for reliable persistence
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Store cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Apply themed colors to UI elements
        applyAppTheme()
        
        // Migrate old keys to new format
        migrateUserDefaults()
        
        // Register default values
        registerDefaultValues()
        
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // Only show disclaimer if the user hasn't completed onboarding
                    EnhancedLaunchDisclaimerView(isCompletedOnboarding: $hasCompletedOnboarding)
                        .adaptiveLayout()
                        .background(Color.appBackground)
                        .onDisappear {
                            // Double-check when view disappears that the flag is saved
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            UserDefaults.standard.synchronize()
                        }
                } else {
                    // Main app content
                    ContentView()
                        .environmentObject(drinkTracker)
                        .adaptiveLayout()
                        .background(Color.appBackground)
                        .onAppear {
                            setupAppConfiguration()
                            syncDrinkDataToWatch()
                            // Connect DrinkTracker to WatchSessionManager
                            WatchSessionManager.shared.setDrinkTracker(drinkTracker)
                        }
                }
            }
            .background(Color.appBackground) // Global background
        }
    }
    
    // Migrate old keys to new format for compatibility
    private func migrateUserDefaults() {
        // If we have old values but not the new one, migrate them
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            let hasSeenDisclaimer = UserDefaults.standard.bool(forKey: "hasSeenDisclaimer")
            let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
            
            // If either old flag was true, set the new one to true
            if hasSeenDisclaimer || hasCompletedSetup {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                self.hasCompletedOnboarding = true
            }
            
            // Clean up old keys
            UserDefaults.standard.removeObject(forKey: "hasSeenDisclaimer")
            UserDefaults.standard.removeObject(forKey: "hasCompletedSetup")
            UserDefaults.standard.synchronize()
        }
    }
    
    // Register default values
    private func registerDefaultValues() {
        let defaults: [String: Any] = [
            "hasCompletedOnboarding": false,
            "currentDrinkCount": 0.0,
            "drinkLimit": 4.0
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    
    // Reload settings when needed
    private func reloadSettingsIfNeeded() {
        // We could add additional logic here if needed
        // For now, the @AppStorage handles most of this automatically
    }
    
    // Persist all important data
    private func persistAllData() {
        // Ensure all critical data is saved before app goes to background
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()
    }
    
    private func setupAppConfiguration() {
        // Check purchase status
        checkPurchaseStatus()
        
        // Request permissions for notifications
        requestNotificationPermissions()
        
        // Apply user's theme setting
        AppSettingsManager.shared.applyAppearanceSettings()
    }
    
    private func checkPurchaseStatus() {
        // In a real app, this would check with StoreKit to verify purchases
        if UserDefaults.standard.bool(forKey: "hasPurchasedApp") {
            hasCompletedOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.synchronize()
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // Setup notification categories for different types of notifications
                self.setupNotificationCategories()
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create actions for notifications
        let getUberAction = UNNotificationAction(
            identifier: "GET_UBER",
            title: "Get Uber",
            options: .foreground
        )
        
        let getLyftAction = UNNotificationAction(
            identifier: "GET_LYFT",
            title: "Get Lyft",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        
        // Create notification category
        let bacCategory = UNNotificationCategory(
            identifier: "BAC_ALERT",
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([bacCategory])
    }
    
    private func syncDrinkDataToWatch() {
        // Send data via WatchConnectivity
        WatchSessionManager.shared.sendDrinkDataToWatch(
            drinkCount: drinkTracker.standardDrinkCount,
            drinkLimit: drinkTracker.drinkLimit,
            timeUntilReset: drinkTracker.timeUntilReset
        )
        
        // UserDefaults
        UserDefaults.standard.set(drinkTracker.standardDrinkCount, forKey: "currentDrinkCount")
        UserDefaults.standard.set(drinkTracker.timeUntilReset, forKey: "timeUntilReset")
        UserDefaults.standard.synchronize()
    }
    
    // Add new method to apply custom theme colors
    func applyAppTheme() {
        // Set up the navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appCardBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.appCardBackground)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    // MARK: - Enhanced Disclaimer View
    struct EnhancedLaunchDisclaimerView: View {
        @Binding var isCompletedOnboarding: Bool
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
        var body: some View {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Rectangle()
                        .fill(Color.appCardBackground)
                        .frame(height: 100)
                        .edgesIgnoringSafeArea(.top)
                    
                    VStack {
                        Spacer()
                        Text("Important Disclaimer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appTextPrimary)
                            .padding(.bottom, 10)
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Warning icon
                        ZStack {
                            Circle()
                                .fill(Color("WarningBackground"))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(Color.warning)
                        }
                        .padding(.top, 30)
                        
                        // Main disclaimer content
                        VStack(alignment: .leading, spacing: 25) {
                            DisclaimerSection(
                                title: "BarBuddy provides guidance only",
                                items: [
                                    "The drink calculations are estimates and should not be relied on for legal purposes.",
                                    "Many factors affect how alcohol impacts your body that this app cannot measure.",
                                    "Never drive after consuming alcohol, regardless of what this app indicates.",
                                    "The only safe option when driving is to not drink at all.",
                                    "This app is for informational and educational purposes only."
                                ]
                            )
                            
                            // Separator
                            Rectangle()
                                .fill(Color.appSeparator)
                                .frame(height: 1)
                            
                            Text("By using BarBuddy, you acknowledge these limitations and agree to use the app responsibly.")
                                .font(.headline)
                                .foregroundColor(Color.warning)
                                .padding(.vertical, 5)
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 20)
                        .background(Color.appCardBackground)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                // Update the AppStorage binding and explicitly set UserDefaults
                                // for extra redundancy
                                isCompletedOnboarding = true
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                UserDefaults.standard.synchronize()
                                
                                // Also clear old flags just to be safe
                                UserDefaults.standard.removeObject(forKey: "hasSeenDisclaimer")
                                UserDefaults.standard.removeObject(forKey: "hasCompletedSetup")
                                UserDefaults.standard.synchronize()
                            }) {
                                Text("I Understand and Accept")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(LinearGradient(
                                        gradient: Gradient(colors: [Color("AccentColor"), Color("AccentColorDark")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .cornerRadius(30)
                                    .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal, 20)
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                // Exit the app - in a real app you'd want to handle this differently
                                exit(0)
                            }) {
                                Text("Exit App")
                                    .font(.headline)
                                    .foregroundColor(Color.appTextSecondary)
                                    .padding()
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
                .background(Color.appBackground)
            }
        }
    }
    
    struct DisclaimerSection: View {
        let title: String
        let items: [String]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.appTextPrimary)
                
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 7))
                                .foregroundColor(Color.accent)
                                .padding(.top, 6)
                            
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(Color.appTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}
