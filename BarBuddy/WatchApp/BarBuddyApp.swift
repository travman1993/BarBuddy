//
//  BarBuddyApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

@main
struct BarBuddyWatchApp: App {
    @StateObject private var drinkTracker = DrinkTracker()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                WatchContentView()
                    .environmentObject(drinkTracker)
            }
        }
    }
}

// Renamed to WatchContentView to avoid name collision
struct WatchContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        TabView {
            // Dashboard View
            WatchDashboardView()
                .environmentObject(drinkTracker)
            
            // Quick Add Drinks View
            QuickAddDrinksView()
                .environmentObject(drinkTracker)
            
            // Emergency & Ride Options
            EmergencyOptionsView()
                .environmentObject(drinkTracker)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

// Dashboard View
struct WatchDashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
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
        }
        .padding()
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
}

// Quick Add Drinks View
struct QuickAddDrinksView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingConfirmation = false
    @State private var lastAddedDrink: DrinkType?
    
    let drinkTypes: [DrinkType] = [.beer, .wine, .cocktail, .shot]
    
    var body: some View {
        VStack {
            Text("Quick Add")
                .font(.headline)
                .padding(.top, 5)
            
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
                        }
                    }
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
        drinkTracker.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        lastAddedDrink = type
        showingConfirmation = true
        
        // Provide haptic feedback - use UINotificationFeedbackGenerator as WKInterfaceDevice is unavailable
        #if os(watchOS)
        // WatchKit haptic feedback would go here if available
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// Emergency & Ride Options
struct EmergencyOptionsView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Get Home Safe")
                .font(.headline)
            
            Button(action: getUber) {
                HStack {
                    Image(systemName: "car.fill")
                    Text("Uber")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button(action: getLyft) {
                HStack {
                    Image(systemName: "car.fill")
                    Text("Lyft")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            
            Divider()
            
            Button(action: contactEmergency) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Emergency Contact")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            
            if drinkTracker.currentBAC > 0 {
                Button(action: shareStatus) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Status")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.horizontal)
    }
    
    private func getUber() {
        // In a real app, this would use watchOS connectivity to open Uber on the phone
        // or use a deep link if Uber has a watchOS app
    }
    
    private func getLyft() {
        // Similar to getUber
    }
    
    private func contactEmergency() {
        // In a real app, this would initiate messaging or calling to emergency contact
    }
    
    private func shareStatus() {
        // In a real app, this would share status with preset contacts
    }
}

#Preview {
    let drinkTracker = DrinkTracker()
    // Add a test drink to have a non-zero BAC
    drinkTracker.addDrink(type: .beer, size: 12, alcoholPercentage: 5)
    
    return Group {
        WatchContentView()
            .environmentObject(drinkTracker)
        
        WatchDashboardView()
            .environmentObject(drinkTracker)
        
        QuickAddDrinksView()
            .environmentObject(drinkTracker)
        
        EmergencyOptionsView()
            .environmentObject(drinkTracker)
    }
}
