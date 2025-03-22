//
//  BarBuddyApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI
import StoreKit

@main
struct BarBuddyApp: App {
    // Create a single instance of DrinkTracker that will be shared throughout the app
    @StateObject private var drinkTracker = DrinkTracker()
    @State private var hasCompletedPurchase = false
    @State private var showingDisclaimerOnLaunch = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingDisclaimerOnLaunch {
                    LaunchDisclaimerView(isPresented: $showingDisclaimerOnLaunch)
                } else if !hasCompletedPurchase {
                    PurchaseView(hasCompletedPurchase: $hasCompletedPurchase)
                } else {
                    ContentView()
                        .environmentObject(drinkTracker)
                        .onAppear {
                            // Set up app when it appears
                            setupAppConfiguration()
                            
                            // For watchOS communication, sync current BAC
                            syncBACToWatch()
                        }
                }
            }
            // This modifier avoids the issue with buildExpression
            .onAppear {
                // Initial setup code
                checkIfFirstLaunch()
            }
        }
    }
    
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
        // Register defaults
        if UserDefaults.standard.object(forKey: "hasSeenDisclaimer") == nil {
            UserDefaults.standard.set(false, forKey: "hasSeenDisclaimer")
        }
        
        // Check purchase status
        checkPurchaseStatus()
        
        // Request permissions for notifications
        requestNotificationPermissions()
    }
    
    private func checkPurchaseStatus() {
        // In a real app, this would check with StoreKit to verify purchases
        // For now, we'll just use UserDefaults
        if UserDefaults.standard.bool(forKey: "hasPurchasedApp") {
            hasCompletedPurchase = true
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
        // Send data via WatchConnectivity
        WatchSessionManager.shared.sendBACDataToWatch(
            bac: drinkTracker.currentBAC,
            timeUntilSober: drinkTracker.timeUntilSober
        )
        
        // Also keep UserDefaults for backward compatibility
        UserDefaults.standard.set(drinkTracker.currentBAC, forKey: "currentBAC")
        UserDefaults.standard.set(drinkTracker.timeUntilSober, forKey: "timeUntilSober")
    }

struct LaunchDisclaimerView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Important Disclaimer")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("BarBuddy provides estimates only.")
                    .font(.headline)
                
                Text("• The BAC calculations are estimates and should not be relied on for legal purposes.")
                
                Text("• Many factors affect your actual BAC that this app cannot measure.")
                
                Text("• Never drive after consuming alcohol, regardless of what this app indicates.")
                
                Text("• The only safe BAC when driving is 0.00%.")
                
                Text("• This app is for informational and educational purposes only.")
            }
            .padding()
            
            Spacer()
            
            VStack {
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasSeenDisclaimer")
                    isPresented = false
                }) {
                    Text("I Understand and Accept")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // Exit the app - in a real app you'd want to handle this differently
                    exit(0)
                }) {
                    Text("Exit App")
                        .padding()
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct PurchaseView: View {
    @Binding var hasCompletedPurchase: Bool
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "wineglass")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("BarBuddy")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your Personal Drinking Companion")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "gauge", title: "Real-time BAC Tracking", description: "Monitor your estimated blood alcohol content")
                
                FeatureRow(icon: "person.2", title: "Share Status with Friends", description: "Let your friends know your status and stay safe")
                
                FeatureRow(icon: "car", title: "Rideshare Integration", description: "Quick access to Uber and Lyft when you need a ride")
                
                FeatureRow(icon: "applewatch", title: "Apple Watch Support", description: "Log drinks and check your BAC right from your wrist")
            }
            .padding()
            
            Spacer()
            
            // Purchase button
            Button(action: {
                purchaseApp()
            }) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Purchase for $9.99")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(isProcessing)
            
            // Note about purchase
            Text("One-time purchase, no subscriptions.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
    
    private func purchaseApp() {
        isProcessing = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In a real app, this would use StoreKit to process the purchase
            UserDefaults.standard.set(true, forKey: "hasPurchasedApp")
            hasCompletedPurchase = true
            isProcessing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Instead of trying to preview the App struct directly,
// create a separate preview for each main view component
#Preview("Disclaimer View") {
    LaunchDisclaimerView(isPresented: .constant(true))
}

#Preview("Purchase View") {
    PurchaseView(hasCompletedPurchase: .constant(false))
}

// Main content preview is already in ContentView.swift
