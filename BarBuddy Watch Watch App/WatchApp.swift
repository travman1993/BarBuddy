//
//  WatchApp.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/22/25.
//
import SwiftUI
import WatchConnectivity
#if os(watchOS)
import WatchKit
#endif

@main
struct WatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var drinkTracker = DrinkTracker()
    @State private var isLoading = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                ContentView()
                    .environmentObject(sessionManager)
                    .environmentObject(drinkTracker)
                    .opacity(isLoading ? 0 : 1)
                
                // Loading screen
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Simulate loading time and initial data fetch
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isLoading = false
                    }
                }
                
                // Request initial data from phone while showing loading screen
                sessionManager.requestInitialData()
            }
        }
    }
}

// Loading Screen View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // App logo/icon
            Image(systemName: "wineglass.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("BarBuddy")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 10)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            
            // Simple activity indicator
            ProgressView()
                .padding(.top, 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            isAnimating = true
            WKInterfaceDevice.current().play(.click)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            // Dashboard View
            WatchDashboardView()
                .tag(0)
            
            // Quick Add Drinks View
            WatchQuickAddView()
                .tag(1)
            
            // Status Messages View
            WatchStatusMessageView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .onAppear {
            // Set a nice accent color for the whole UI
            WKInterfaceDevice.current().play(.click)
        }
    }
}

// Enhanced Dashboard View
struct WatchDashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Enhanced BAC Circle
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 140, height: 140)
                    
                    // BAC Progress
                    Circle()
                        .trim(from: 0, to: min(CGFloat(drinkTracker.currentBAC * 4), 1.0))
                        .stroke(bacColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: drinkTracker.currentBAC)
                    
                    // Text layers
                    VStack(spacing: 0) {
                        Text("BAC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.3f", drinkTracker.currentBAC))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(bacColor)
                        
                        Text(safetyStatus)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(bacColor)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 8)
                            .background(
                                Capsule()
                                    .fill(bacColor.opacity(0.15))
                            )
                    }
                }
                .padding(.top, 5)
                
                // Time Until Sober
                if drinkTracker.timeUntilSober > 0 {
                    Divider()
                        .padding(.vertical, 5)
                    
                    VStack(spacing: 5) {
                        Text("Safe to drive in")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(bacColor)
                            
                            Text(formattedTimeUntilSober)
                                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        }
                    }
                    .padding(.vertical, 5)
                }
                
                // Last drink info
                if !drinkTracker.drinks.isEmpty, let lastDrink = drinkTracker.drinks.last {
                    Divider()
                        .padding(.vertical, 5)
                        
                    VStack(spacing: 3) {
                        Text("Last drink")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text(lastDrink.type.icon)
                                .font(.system(size: 18))
                            
                            Text(lastDrink.type.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                
                            Text(timeAgo(lastDrink.timestamp))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            .animation(.easeOut(duration: 0.3), value: drinkTracker.currentBAC)
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
            return "\(minutes) min"
        }
    }
    
    func timeAgo(_ date: Date) -> String {
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h \(minutes % 60)m ago"
    }
}

// Enhanced Quick Add View
struct WatchQuickAddView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @EnvironmentObject var sessionManager: WatchSessionManager
    @State private var showingConfirmation = false
    @State private var lastAddedDrink: DrinkType?
    
    let drinkTypes: [DrinkType] = [.beer, .wine, .cocktail, .shot]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Quick Add")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 5)
                
                // Confirmation animation
                if showingConfirmation, let drink = lastAddedDrink {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(drink.rawValue) added")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Drink buttons - enhanced visuals
                ForEach(drinkTypes, id: \.self) { drinkType in
                    Button {
                        addDrink(type: drinkType)
                    } label: {
                        HStack {
                            Text(drinkType.icon)
                                .font(.system(size: 24))
                                .frame(width: 35, alignment: .center)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drinkType.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("\(Int(drinkType.defaultSize))oz, \(Int(drinkType.defaultAlcoholPercentage))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(drinkTypeColor(drinkType))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 4)
                }
                
                // Standard drinks info
                if let lastDrink = drinkTracker.drinks.last {
                    Spacer()
                    Divider()
                        .padding(.vertical, 5)
                    
                    VStack(spacing: 2) {
                        Text("Standard Drinks Today")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f", calculateStandardDrinksToday()))
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.bottom, 5)
                }
            }
            .padding()
        }
    }
    
    private func addDrink(type: DrinkType) {
        // Add drink locally
        drinkTracker.addDrink(
            type: type,
            size: type.defaultSize,
            alcoholPercentage: type.defaultAlcoholPercentage
        )
        
        // Send to phone if connected
        sessionManager.logDrink(type: type)
        
        // Show confirmation
        withAnimation {
            lastAddedDrink = type
            showingConfirmation = true
        }
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        // Hide confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingConfirmation = false
            }
        }
    }
    
    private func drinkTypeColor(_ type: DrinkType) -> Color {
        switch type {
        case .beer:
            return Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
        case .wine:
            return Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
        case .cocktail:
            return Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
        case .shot:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Gray
        default:
            return .blue
        }
    }
    
    private func calculateStandardDrinksToday() -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return drinkTracker.drinks
            .filter { calendar.isDate($0.timestamp, inSameDayAs: Date()) }
            .reduce(0) { $0 + $1.standardDrinks }
    }
}

// Enhanced Status Message View
struct WatchStatusMessageView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var isSending = false
    @State private var showingConfirmation = false
    @State private var selectedMessage = ""
    @State private var showingContactsSheet = false
    @State private var showingRideOptions = false
    
    // Sample emergency contacts - in a real app, these would come from the phone app
    let emergencyContacts: [EmergencyContact] = [
        EmergencyContact(name: "Alex", phoneNumber: "555-1234", relationshipType: "Friend", sendAutomaticTexts: true),
        EmergencyContact(name: "Sam", phoneNumber: "555-5678", relationshipType: "Family", sendAutomaticTexts: true),
        EmergencyContact(name: "Taylor", phoneNumber: "555-9012", relationshipType: "Partner", sendAutomaticTexts: true)
    ]
    
    // Predefined status messages
    let statusMessages = [
        "I made it home safe",
        "I'm getting a ride home",
        "I'm staying at a friend's",
        "Will be home in 30 minutes"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Send Status")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 5)
                
                // Confirmation animation
                if showingConfirmation {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Message sent")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Status message buttons
                ForEach(statusMessages, id: \.self) { message in
                    Button {
                        selectedMessage = message
                        showingContactsSheet = true
                    } label: {
                        Text(message)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSending)
                }
                
                Divider()
                    .padding(.vertical, 6)
                
                // Share BAC Status
                if drinkTracker.currentBAC > 0 {
                    Button {
                        selectedMessage = "My current BAC is \(String(format: "%.3f", drinkTracker.currentBAC))"
                        showingContactsSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 16))
                            Text("Share BAC Status")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSending)
                }
                
                // Ride service buttons
                Button {
                    showingRideOptions = true
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                        Text("Get a Ride")
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isSending)
                .sheet(isPresented: $showingRideOptions) {
                    RideOptionsView()
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingContactsSheet) {
                ContactSelectionView(
                    contacts: emergencyContacts,
                    message: selectedMessage,
                    onSend: { recipients in
                        sendMessage(selectedMessage, to: recipients)
                    }
                )
            }
        }
    }
    
    private func sendMessage(_ message: String, to recipients: [EmergencyContact]) {
        isSending = true
        
        // Simulate sending
        WKInterfaceDevice.current().play(.click)
        
        // Show success after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSending = false
            withAnimation {
                showingConfirmation = true
            }
            WKInterfaceDevice.current().play(.success)
            
            // Hide confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingConfirmation = false
                }
            }
        }
    }
}

// Contact Selection View
struct ContactSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    let contacts: [EmergencyContact]
    let message: String
    let onSend: ([EmergencyContact]) -> Void
    
    @State private var selectedContacts: Set<String> = []
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Send to")
                .font(.headline)
                .padding(.top, 5)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            
            List {
                ForEach(contacts, id: \.id) { contact in
                    Button {
                        toggleSelection(contact)
                    } label: {
                        HStack {
                            Text(contact.name)
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            if selectedContacts.contains(contact.id.uuidString) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(CarouselListStyle())
            
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button {
                    let selectedEmergencyContacts = contacts.filter { selectedContacts.contains($0.id.uuidString) }
                    onSend(selectedEmergencyContacts)
                    isSending = true
                    
                    // Dismiss after slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                } label: {
                    Text("Send")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selectedContacts.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedContacts.isEmpty || isSending)
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
        }
    }
    
    private func toggleSelection(_ contact: EmergencyContact) {
        let id = contact.id.uuidString
        if selectedContacts.contains(id) {
            selectedContacts.remove(id)
        } else {
            selectedContacts.insert(id)
        }
        WKInterfaceDevice.current().play(.click)
    }
}

// Ride Options View
struct RideOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Get a Ride")
                .font(.headline)
                .padding(.top, 5)
            
            if isProcessing {
                ProgressView()
                    .padding()
            } else {
                // Uber Button
                Button {
                    requestRide(service: "uber")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 15))
                        Text("Uber")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1)) // Uber black
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Lyft Button
                Button {
                    requestRide(service: "lyft")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 15))
                        Text("Lyft")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.82, green: 0.0, blue: 0.42)) // Lyft pink
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Emergency Contact Button
                Button {
                    requestEmergencyRide()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 15))
                        Text("Call Contact for Ride")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Cancel Button
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                        .padding(.vertical, 10)
                }
            }
        }
        .padding()
    }
    
    private func requestRide(service: String) {
        isProcessing = true
        WKInterfaceDevice.current().play(.click)
        
        // Simulate calling the ride service API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func requestEmergencyRide() {
        isProcessing = true
        WKInterfaceDevice.current().play(.notification)
        
        // Simulate calling emergency contact
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}
