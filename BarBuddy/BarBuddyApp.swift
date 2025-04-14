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
        
        // Apply themed colors to UI elements
        applyAppTheme()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingDisclaimerOnLaunch {
                    EnhancedLaunchDisclaimerView(isPresented: $showingDisclaimerOnLaunch)
                        .adaptiveLayout()
                        .background(Color.appBackground)
                } else if !hasCompletedPurchase {
                    EnhancedUserSetupView(hasCompletedSetup: $hasCompletedPurchase)
                        .adaptiveLayout()
                        .background(Color.appBackground)
                } else {
                    ContentView()
                        .environmentObject(drinkTracker)
                        .adaptiveLayout()
                        .background(Color.appBackground)
                        .onAppear {
                            setupAppConfiguration()
                            syncBACToWatch()
                            // Connect DrinkTracker to WatchSessionManager
                            WatchSessionManager.shared.setDrinkTracker(drinkTracker)
                        }
                }
            }
            .background(Color.appBackground) // Global background
            .onAppear {
                checkIfFirstLaunch()
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
    
    private func syncBACToWatch() {
        // Send data via WatchConnectivity
        WatchSessionManager.shared.sendDrinkDataToWatch(
            drinkCount: drinkTracker.standardDrinkCount,
            drinkLimit: drinkTracker.drinkLimit,
            timeUntilReset: drinkTracker.timeUntilReset
        )
        
        // UserDefaults
        UserDefaults.standard.set(drinkTracker.standardDrinkCount, forKey: "currentDrinkCount")
        UserDefaults.standard.set(drinkTracker.timeUntilReset, forKey: "timeUntilReset")
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
                                UserDefaults.standard.set(true, forKey: "hasSeenDisclaimer")
                                isPresented = false
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
    
    // Enhancing EnhancedUserSetupView in BarBuddyApp.swift
    struct EnhancedUserSetupView: View {
        @Binding var hasCompletedSetup: Bool
        @State private var weight: Double = 160.0
        @State private var gender: Gender = .male
        @State private var currentPage = 0
        @State private var showUnitSelector = false
        @State private var useMetricUnits = false
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
        var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(currentStep: currentPage, totalSteps: 3)
                        .padding(.top)
                    
                    TabView(selection: $currentPage) {
                        // Welcome screen
                        WelcomeView(nextAction: { currentPage = 1 })
                            .tag(0)
                        
                        // Profile setup
                        VStack(spacing: 30) {
                            // Header
                            Text("Tell us about yourself")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top, 40)
                            
                            // Weight selection
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("Your Weight")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: { showUnitSelector = true }) {
                                        Text(useMetricUnits ? "kg" : "lbs")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                HStack {
                                    Text(weightDisplay)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Slider(value: $weight, in: useMetricUnits ? 40...180 : 88...396, step: 1)
                                        .accentColor(Color.accent)
                                }
                                
                                Text("We use this to calculate more accurately")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            
                            // Gender selection
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Your Gender")
                                    .font(.headline)
                                
                                HStack(spacing: 15) {
                                    GenderButton(
                                        title: "Male",
                                        icon: "person.fill",
                                        isSelected: gender == .male,
                                        action: { gender = .male }
                                    )
                                    
                                    GenderButton(
                                        title: "Female",
                                        icon: "person.fill",
                                        isSelected: gender == .female,
                                        action: { gender = .female }
                                    )
                                }
                                
                                Text("Gender affects how your body processes alcohol")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            // Navigation buttons
                            HStack {
                                Button(action: { currentPage = 0 }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .padding()
                                    .foregroundColor(.blue)
                                }
                                
                                Spacer()
                                
                                Button(action: { currentPage = 2 }) {
                                    HStack {
                                        Text("Next")
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.accent)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                        .tag(1)
                        
                        // Settings & Completion
                        FinalSetupView(
                            weight: weight,
                            gender: gender,
                            useMetricUnits: useMetricUnits,
                            onComplete: {
                                saveUserProfile()
                                hasCompletedSetup = true
                            }
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                }
                .actionSheet(isPresented: $showUnitSelector) {
                    ActionSheet(
                        title: Text("Select Unit"),
                        buttons: [
                            .default(Text("Pounds (lbs)")) {
                                if useMetricUnits {
                                    // Convert kg to lbs
                                    weight = weight * 2.20462
                                    useMetricUnits = false
                                }
                            },
                            .default(Text("Kilograms (kg)")) {
                                if !useMetricUnits {
                                    // Convert lbs to kg
                                    weight = weight / 2.20462
                                    useMetricUnits = true
                                }
                            },
                            .cancel()
                        ]
                    )
                }
            }
            .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        }
        
        private var weightDisplay: String {
            if useMetricUnits {
                return "\(Int(weight)) kg"
            } else {
                return "\(Int(weight)) lbs"
            }
        }
        
        private func saveUserProfile() {
            // Ensure weight is saved in pounds for consistency
            let weightInPounds = useMetricUnits ? weight * 2.20462 : weight
            
            let profile = UserProfile(
                weight: weightInPounds,
                gender: gender,
                emergencyContacts: []
            )
            
            // Save to DrinkTracker
            let drinkTracker = DrinkTracker()
            drinkTracker.updateUserProfile(profile)
            
            // Also update settings manager
            AppSettingsManager.shared.weight = weightInPounds
            AppSettingsManager.shared.gender = gender
            AppSettingsManager.shared.useMetricUnits = useMetricUnits
            AppSettingsManager.shared.saveSettings()
        }
    }
    
    // Supporting components for the enhanced onboarding
    struct WelcomeView: View {
        let nextAction: () -> Void
        
        var body: some View {
            VStack(spacing: 30) {
                Spacer()
                
                // App logo and title
                VStack(spacing: 15) {
                    Image(systemName: "wineglass")
                        .font(.system(size: 80))
                        .foregroundColor(Color.accent)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.accent.opacity(0.1))
                                .frame(width: 150, height: 150)
                        )
                    
                    Text("Welcome to BarBuddy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your personal drinking companion")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Key features
                VStack(alignment: .leading, spacing: 15) {
                    FeatureRow(icon: "chart.bar", title: "Track your drink consumption")
                    FeatureRow(icon: "calendar", title: "Monitor drinking patterns")
                    FeatureRow(icon: "person.2", title: "Share your drinking status")
                    FeatureRow(icon: "list.clipboard", title: "Set daily drink limits")
                    FeatureRow(icon: "stopwatch", title: "Track time between drinks")
                    FeatureRow(icon: "car", title: "Get home safely with rideshare")
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                // Start button
                Button(action: nextAction) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    struct FinalSetupView: View {
        let weight: Double
        let gender: Gender
        let useMetricUnits: Bool
        let onComplete: () -> Void
        @State private var enableNotifications = true
        @State private var enableLocationServices = true
        
        var body: some View {
            VStack(spacing: 30) {
                // Header
                Text("Almost done!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                // Profile summary
                VStack(alignment: .leading, spacing: 15) {
                    Text("Your Profile")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(Color.accent)
                                Text("Weight:")
                                    .foregroundColor(.secondary)
                                Text(useMetricUnits ? "\(Int(weight)) kg" : "\(Int(weight)) lbs")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Color.accent)
                                Text("Gender:")
                                    .foregroundColor(.secondary)
                                Text(gender.rawValue)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
                
                // App permissions
                VStack(alignment: .leading, spacing: 15) {
                    Text("App Permissions")
                        .font(.headline)
                    
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    
                    Text("Allows alerts, hydration reminders, and safety check-ins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle("Enable Location Services", isOn: $enableLocationServices)
                    
                    Text("For accurate location sharing during emergencies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
                
                // Complete button
                Button(action: {
                    if enableNotifications {
                        requestNotificationPermissions()
                    }
                    
                    if enableLocationServices {
                        requestLocationPermissions()
                    }
                    
                    onComplete()
                }) {
                    Text("Complete Setup")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accent)
                        .cornerRadius(15)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
        
        private func requestNotificationPermissions() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    // Setup notification categories for different types of notifications
                    NotificationManager.shared.setupNotificationCategories()
                }
            }
        }
        
        private func requestLocationPermissions() {
            // This would integrate with LocationManager to request permissions
            // Placeholder for now
        }
    }
    
    struct ProgressBar: View {
        let currentStep: Int
        let totalSteps: Int
        
        var body: some View {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accent : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
        }
    }
    
    struct FeatureRow: View {
        let icon: String
        let title: String
        
        var body: some View {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.accent)
                    .frame(width: 30)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
            }
        }
    }
    
    struct GenderButton: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(isSelected ? .white : Color.accent)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.accent : Color.appCardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.accent, lineWidth: 2)
                )
            }
        }
    }
}
