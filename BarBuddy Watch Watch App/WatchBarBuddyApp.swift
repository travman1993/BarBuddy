//
//  WatchBarBuddyApp.swift
//  BarBuddy Watch Watch App
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI
import WatchConnectivity
#if os(watchOS)
import WatchKit
#endif

@main
struct BarBuddyWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var drinkTracker = DrinkTracker()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchContentView()
                    .environmentObject(sessionManager)
                    .environmentObject(drinkTracker)
            }
            .onAppear {
                // Request initial data when app launches
                sessionManager.requestInitialData()
            }
        }
    }
}

// Renamed to WatchContentView to avoid name collision
struct WatchContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var tabSelection: Int = 0
    
    var body: some View {
        TabView(selection: $tabSelection) {
            // Dashboard View
            WatchDashboardView()
                .environmentObject(drinkTracker)
                .tag(0)
            
            // Quick Add Drinks View
            QuickAddDrinksView()
                .environmentObject(drinkTracker)
                .tag(1)
            
            // Emergency Options View
            WatchEmergencyOptionsView()
                .environmentObject(drinkTracker)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .onReceive(sessionManager.$currentBAC) { newBAC in
            // Update drinkTracker when data comes from phone
            if newBAC != drinkTracker.currentBAC {
                drinkTracker.updateBACFromWatch(bac: newBAC, timeUntilSober: sessionManager.timeUntilSober)
            }
        }
    }
}

// Dashboard View
struct WatchDashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var refreshing: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // BAC Display
                Text("BAC")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(String(format: "%.3f", drinkTracker.currentBAC))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(bacColor)
                
                // Safety Status
                Text(safetyStatus)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(bacColor.opacity(0.3))
                    .cornerRadius(4)
                
                if drinkTracker.timeUntilSober > 0 {
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Time Until Sober
                    Text("Safe to drive in")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(formattedTimeUntilSober)
                        .font(.footnote)
                }
                
                // Pull to refresh implementation
                Button(action: refreshData) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(refreshing ? "Updating..." : "Refresh Data")
                            .font(.caption)
                    }
                }
                .disabled(refreshing)
                .padding(.top, 10)
            }
            .padding()
        }
    }
    
    var bacColor: Color {
        if drinkTracker.currentBAC < 0.04 {
            return .green
        } else if drinkTracker.currentBAC < 0.08 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var safetyStatus: String {
        if drinkTracker.currentBAC < 0.04 {
            return "Safe to Drive"
        } else if drinkTracker.currentBAC < 0.08 {
            return "Borderline"
        } else {
            return "DO NOT DRIVE"
        }
    }
    
    var formattedTimeUntilSober: String {
        let hours = Int(drinkTracker.timeUntilSober) / 3600
        let minutes = (Int(drinkTracker.timeUntilSober) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    func refreshData() {
        refreshing = true
        WatchSessionManager.shared.requestLatestBAC()
        
        // Simulate network delay and then stop refreshing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            refreshing = false
        }
    }
}

// Quick Add Drinks View
struct QuickAddDrinksView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingConfirmation = false
    @State private var lastAddedDrink: DrinkType?
    @State private var syncing = false
    
    let drinkTypes: [DrinkType] = [.beer, .wine, .cocktail, .shot]
    
    var body: some View {
        VStack {
            Text("Quick Add")
                .font(.headline)
                .padding(.top, 5)
            
            if syncing {
                Text("Syncing with phone...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 5)
            }
            
            List {
                ForEach(drinkTypes, id: \.self) { drinkType in
                    Button(action: {
                        addDrink(type: drinkType)
                    }) {
                        HStack {
                            Text(drinkType.icon)
                                .font(.title3)
                            
                            Text(drinkType.rawValue)
                                .font(.body)
                            
                            Spacer()
                            
                            Text("\(Int(drinkType.defaultSize))oz, \(Int(drinkType.defaultAlcoholPercentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(syncing)
                }
            }
            
            if showingConfirmation {
                HStack {
                    if let drink = lastAddedDrink {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(drink.rawValue) added")
                            .font(.caption)
                    }
                }
                .padding(.bottom, 5)
                .onAppear {
                    // Hide confirmation after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingConfirmation = false
                    }
                }
            }
        }
    }
    
    private func addDrink(type: DrinkType) {
        // Start syncing state
        syncing = true
        
        // Update local tracker for UI updates
        drinkTracker.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Update UI
        lastAddedDrink = type
        showingConfirmation = true
        
        // Send drink info to iPhone
        WatchSessionManager.shared.logDrink(type: type) { success in
            // Update UI on main thread to reflect sync state
            DispatchQueue.main.async {
                syncing = false
                
                // If failed to sync, we could show a retry button or error message
                if !success {
                    // Store for later retry
                    WatchSessionManager.shared.addToPendingDrinks(type: type)
                }
            }
        }
        
        // Provide haptic feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// Emergency & Ride Options - renamed to fix the scope issue
struct WatchEmergencyOptionsView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var requestingRide = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Get Home Safe")
                    .font(.headline)
                
                if requestingRide {
                    ProgressView()
                        .padding()
                }
                
                Button(action: getUber) {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Uber")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(requestingRide)
                
                Button(action: getLyft) {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Lyft")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.white)
                .background(Color.pink)
                .cornerRadius(8)
                .disabled(requestingRide)
                
                Divider()
                
                Button(action: contactEmergency) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Emergency Contact")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(8)
                .disabled(requestingRide)
                
                if drinkTracker.currentBAC > 0 {
                    Button(action: shareStatus) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Status")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(8)
                    .disabled(requestingRide)
                }
            }
            .padding(.horizontal)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func getUber() {
        requestingRide = true
        
        // Send request to phone to open Uber
        WatchSessionManager.shared.requestRideService(service: "uber") { success in
            DispatchQueue.main.async {
                requestingRide = false
                showingAlert = true
                alertMessage = success ?
                    "Uber request sent to phone" :
                    "Could not contact phone. Please open Uber on your iPhone."
            }
        }
        
        // Provide feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
    
    private func getLyft() {
        requestingRide = true
        
        // Send request to phone to open Lyft
        WatchSessionManager.shared.requestRideService(service: "lyft") { success in
            DispatchQueue.main.async {
                requestingRide = false
                showingAlert = true
                alertMessage = success ?
                    "Lyft request sent to phone" :
                    "Could not contact phone. Please open Lyft on your iPhone."
            }
        }
        
        // Provide feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
    
    private func contactEmergency() {
        // In a real app, this would initiate messaging or calling to emergency contact
        requestingRide = true
        
        // Send request to phone to contact emergency contact
        WatchSessionManager.shared.contactEmergency { success in
            DispatchQueue.main.async {
                requestingRide = false
                showingAlert = true
                alertMessage = success ?
                    "Emergency contact notification sent" :
                    "Could not contact phone. Please use your iPhone to contact someone."
            }
        }
        
        // Provide feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.notification)
        #endif
    }
    
    private func shareStatus() {
        // In a real app, this would share status with preset contacts
        requestingRide = true
        
        // Get current BAC
        let bac = drinkTracker.currentBAC
        
        // Send request to phone to share status
        WatchSessionManager.shared.shareStatus(bac: bac) { success in
            DispatchQueue.main.async {
                requestingRide = false
                showingAlert = true
                alertMessage = success ?
                    "Status shared with designated contacts" :
                    "Could not share status. Please try again or use your iPhone."
            }
        }
        
        // Provide feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }
}
