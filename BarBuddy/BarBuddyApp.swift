//
//  BarBuddyApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
import SwiftUI
import StoreKit

@main
struct BarBuddyApp: App {
    // Keep existing state and observers
    @StateObject private var drinkTracker = DrinkTracker()
    @State private var hasCompletedPurchase = false
    @State private var showingDisclaimerOnLaunch = true
    
    init() {
        // Connect DrinkTracker to WatchSessionManager
        WatchSessionManager.shared.setDrinkTracker(drinkTracker)
        
        // Apply themed colors to UI elements
        applyAppTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingDisclaimerOnLaunch {
                    EnhancedLaunchDisclaimerView(isPresented: $showingDisclaimerOnLaunch)
                        .adaptiveLayout()
                } else if !hasCompletedPurchase {
                    EnhancedUserSetupView(hasCompletedSetup: $hasCompletedPurchase)
                        .adaptiveLayout()
                } else {
                    ContentView()
                        .environmentObject(drinkTracker)
                        .adaptiveLayout()
                        .onAppear {
                            setupAppConfiguration()
                            syncBACToWatch()
                        }
                }
            }
            .onAppear {
                checkIfFirstLaunch()
            }
        }
    }
    }
    
    // Keep your existing methods intact to maintain functionality
    private func checkIfFirstLaunch() {
        // First launch check
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            showingDisclaimerOnLaunch = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            // Not first launch, check disclaimer status
            showingDisclaimerOnLaunch = !UserDefaults.standard.bool(forKey: "hasSeenDisclaimer")
        }
    }
    
    private func setupAppConfiguration() {
        // Keep existing functionality
        // Register defaults
        if UserDefaults.standard.object(forKey: "hasSeenDisclaimer") == nil {
            UserDefaults.standard.set(false, forKey: "hasSeenDisclaimer")
        }
        
        // Check purchase status
        checkPurchaseStatus()
        
        // Request permissions for notifications
        requestNotificationPermissions()
        
        // Apply user's theme setting
        AppSettingsManager.shared.applyAppearanceSettings()
    }
    
    private func checkPurchaseStatus() {
        // In a real app, this would check with StoreKit to verify purchases
        // For now, we'll just use UserDefaults
        if UserDefaults.standard.bool(forKey: "hasPurchasedApp") {
            hasCompletedPurchase = true
        }
    }
    
    private func requestNotificationPermissions() {
        // Keep existing functionality
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // Setup notification categories for different types of notifications
                self.setupNotificationCategories()
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Keep existing functionality
        // Create actions for BAC notifications
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
        
        // Create BAC notification category
        let bacCategory = UNNotificationCategory(
            identifier: "BAC_ALERT",
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([bacCategory])
    }
    
    private func syncBACToWatch() {
        // Keep existing functionality
        // Send data via WatchConnectivity
        WatchSessionManager.shared.sendBACDataToWatch(
            bac: drinkTracker.currentBAC,
            timeUntilSober: drinkTracker.timeUntilSober
        )
        
        // Also keep UserDefaults for backward compatibility
        UserDefaults.standard.set(drinkTracker.currentBAC, forKey: "currentBAC")
        UserDefaults.standard.set(drinkTracker.timeUntilSober, forKey: "timeUntilSober")
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
    @Binding var isPresented: Bool
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
                            .fill(Color.warningBackground)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(Color.warning)
                    }
                    .padding(.top, 30)
                    
                    // Main disclaimer content
                    VStack(alignment: .leading, spacing: 25) {
                        DisclaimerSection(
                            title: "BarBuddy provides estimates only",
                            items: [
                                "The BAC calculations are estimates and should not be relied on for legal purposes.",
                                "Many factors affect your actual BAC that this app cannot measure.",
                                "Never drive after consuming alcohol, regardless of what this app indicates.",
                                "The only safe BAC when driving is 0.00%.",
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
                            UserDefaults.standard.set(true, forKey: "hasSeenDisclaimer")
                            isPresented = false
                        }) {
                            Text("I Understand and Accept")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing))
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

// MARK: - Enhanced User Setup View
struct EnhancedUserSetupView: View {
    @Binding var hasCompletedSetup: Bool
    @State private var weight: Double = 160.0
    @State private var gender: Gender = .male
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    // Header area with logo
                    VStack(spacing: 15) {
                        // Logo with glow
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(Color.accent.opacity(0.3), lineWidth: 3)
                                .frame(width: 120, height: 120)
                            
                            // Inner ring
                            Circle()
                                .stroke(Color.accent.opacity(0.7), lineWidth: 3)
                                .frame(width: 80, height: 80)
                            
                            // Icon
                            Image(systemName: "wineglass")
                                .font(.system(size: 50))
                                .foregroundColor(Color.accent)
                        }
                        .padding(.top, 20)
                        
                        Text("BarBuddy")
                            .font(.system(size: 40, weight: .bold, design: .default))
                            .foregroundColor(Color.appTextPrimary)
                        
                        Text("Your Personal Drinking Companion")
                            .font(.title3)
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .padding(.bottom, 20)
                    
                    // User profile setup
                    VStack(alignment: .leading, spacing: 25) {
                        Text("YOUR PROFILE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                            .padding(.leading, 15)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(Color.appTextPrimary)
                            
                            HStack {
                                Slider(value: $weight, in: 80...400, step: 1)
                                    .accentColor(Color.accent)
                                
                                Text("\(Int(weight)) lbs")
                                    .font(.headline)
                                    .foregroundColor(Color.appTextPrimary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                        }
                        .padding(.horizontal, 15)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Gender")
                                .font(.headline)
                                .foregroundColor(Color.appTextPrimary)
                            
                            Picker("Gender", selection: $gender) {
                                Text("Male").tag(Gender.male)
                                Text("Female").tag(Gender.female)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.trailing, 15)
                        }
                        .padding(.horizontal, 15)
                    }
                    .padding(.vertical, 25)
                    .background(Color.appCardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    // App features showcase
                    VStack(alignment: .leading, spacing: 25) {
                        Text("FEATURES")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accent)
                            .padding(.leading, 15)
                        
                        if horizontalSizeClass == .regular {
                            // iPad layout: features in 2 columns
                            HStack(alignment: .top, spacing: 30) {
                                VStack(alignment: .leading, spacing: 25) {
                                    EnhancedFeatureRow(icon: "gauge", title: "Real-time BAC Tracking", description: "Monitor your estimated blood alcohol content")
                                    
                                    EnhancedFeatureRow(icon: "person.2", title: "Share Status with Friends", description: "Let your friends know your status and stay safe")
                                }
                                
                                VStack(alignment: .leading, spacing: 25) {
                                    EnhancedFeatureRow(icon: "car", title: "Rideshare Integration", description: "Quick access to Uber and Lyft when you need a ride")
                                    
                                    EnhancedFeatureRow(icon: "exclamationmark.triangle", title: "Emergency Contacts", description: "Set up contacts for when you need assistance")
                                }
                            }
                            .padding(.horizontal, 15)
                        } else {
                            // iPhone layout: features in single column
                            EnhancedFeatureRow(icon: "gauge", title: "Real-time BAC Tracking", description: "Monitor your estimated blood alcohol content")
                                .padding(.horizontal, 15)
                            
                            EnhancedFeatureRow(icon: "person.2", title: "Share Status with Friends", description: "Let your friends know your status and stay safe")
                                .padding(.horizontal, 15)
                            
                            EnhancedFeatureRow(icon: "car", title: "Rideshare Integration", description: "Quick access to Uber and Lyft when you need a ride")
                                .padding(.horizontal, 15)
                            
                            EnhancedFeatureRow(icon: "exclamationmark.triangle", title: "Emergency Contacts", description: "Set up contacts for when you need assistance")
                                .padding(.horizontal, 15)
                        }
                    }
                    .padding(.vertical, 25)
                    .background(Color.appCardBackground)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                    
                    // Continue button
                    Button(action: {
                        saveUserProfile()
                        hasCompletedSetup = true
                    }) {
                        Text("GET STARTED")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(30)
                            .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .background(Color.appBackground)
        }
    }
    
    private func saveUserProfile() {
        let profile = UserProfile(
            weight: weight,
            gender: gender,
            emergencyContacts: []
        )
        
        // Save to DrinkTracker
        let drinkTracker = DrinkTracker()
        drinkTracker.updateUserProfile(profile)
        
        // Also update settings manager
        AppSettingsManager.shared.weight = weight
        AppSettingsManager.shared.gender = gender
        AppSettingsManager.shared.saveSettings()
    }
}
