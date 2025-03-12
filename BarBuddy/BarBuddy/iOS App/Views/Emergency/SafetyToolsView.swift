//
//  SafetyToolsView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI
import MapKit

struct SafetyToolsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    @EnvironmentObject private var emergencyViewModel: EmergencyViewModel
    
    @State private var showingEmergencySheet = false
    @State private var showingRideOptionsSheet = false
    @State private var showingSafetyTipsSheet = false
    @State private var currentLocation: CLLocationCoordinate2D?
    @State private var isLoadingLocation = false
    
    private let locationService = LocationService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.standardPadding) {
                // Current BAC Status
                BACStatusView(bacEstimate: bacViewModel.currentBAC)
                
                // Emergency and Safety Actions
                VStack(spacing: Constants.UI.smallPadding) {
                    // Emergency Contact Button
                    Button {
                        showingEmergencySheet = true
                    } label: {
                        SafetyActionButton(
                            title: "Emergency Alert",
                            icon: "exclamationmark.triangle.fill",
                            description: "Alert your emergency contacts",
                            color: .red
                        )
                    }
                    
                    // Ride Share Button
                    Button {
                        showingRideOptionsSheet = true
                    } label: {
                        SafetyActionButton(
                            title: "Get a Ride",
                            icon: "car.fill",
                            description: "Find a safe ride home",
                            color: .blue
                        )
                    }
                    
                    // Check In Button
                    Button {
                        sendCheckIn()
                    } label: {
                        SafetyActionButton(
                            title: "Send Check-In",
                            icon: "checkmark.circle.fill",
                            description: "Let contacts know you're OK",
                            color: .green
                        )
                    }
                    
                    // Safety Tips Button
                    Button {
                        showingSafetyTipsSheet = true
                    } label: {
                        SafetyActionButton(
                            title: "Safety Tips",
                            icon: "lightbulb.fill",
                            description: "Alcohol safety information",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                // Map (if location available)
                if isLoadingLocation {
                    ProgressView("Getting location...")
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(Constants.UI.cornerRadius)
                        .padding(.horizontal)
                } else if let location = currentLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Current Location")
                            .font(.headline)
                        
                        LocationMapView(coordinate: location)
                            .frame(height: 200)
                            .cornerRadius(Constants.UI.cornerRadius)
                    }
                    .padding(.horizontal)
                }
                
                // Emergency contacts section
                if !emergencyViewModel.contacts.isEmpty {
                    EmergencyContactsSection(contacts: emergencyViewModel.contacts)
                } else {
                    NoContactsWarning()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Safety Tools")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLocation()
            Task {
                await emergencyViewModel.loadContacts(userId: userViewModel.currentUser.id)
            }
        }
        .sheet(isPresented: $showingEmergencySheet) {
            EmergencyAlertView()
        }
        .sheet(isPresented: $showingRideOptionsSheet) {
            // This would be your RideOptionsView
            Text("Ride Options View")
        }
        .sheet(isPresented: $showingSafetyTipsSheet) {
            SafetyTipsView()
        }
    }
    
    private func loadLocation() {
        isLoadingLocation = true
        
        locationService.getCurrentLocation { result in
            isLoadingLocation = false
            
            switch result {
            case .success(let location):
                self.currentLocation = location.coordinate
            case .failure:
                self.currentLocation = nil
            }
        }
    }
    
    private func sendCheckIn() {
        Task {
            do {
                try await emergencyViewModel.sendCheckInMessage(
                    userId: userViewModel.currentUser.id,
                    userName: userViewModel.currentUser.name ?? "User"
                )
            } catch {
                print("Error sending check-in: \(error)")
            }
        }
    }
}

struct BACStatusView: View {
    let bacEstimate: BACEstimate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Status")
                .font(.headline)
            
            HStack(spacing: Constants.UI.largePadding) {
                // BAC Circle
                BACCircleView(bac: bacEstimate.bac, size: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Status text
                    Text(statusText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                    
                    // Time until sober/legal
                    Text(timeRemainingText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Safety advice
                    Text(bacEstimate.advice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .background(statusColor.opacity(0.1))
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .padding(.horizontal)
    }
    
    private var statusText: String {
        if bacEstimate.bac >= Constants.BAC.legalLimit {
            return "DO NOT DRIVE"
        } else if bacEstimate.bac >= Constants.BAC.cautionThreshold {
            return "BE CAUTIOUS"
        } else if bacEstimate.bac > 0 {
            return "UNDER LEGAL LIMIT"
        } else {
            return "SOBER"
        }
    }
    
    private var statusColor: Color {
        if bacEstimate.bac >= Constants.BAC.legalLimit {
            return .dangerBAC
        } else if bacEstimate.bac >= Constants.BAC.cautionThreshold {
            return .cautionBAC
        } else {
            return .safeBAC
        }
    }
    
    private var timeRemainingText: String {
        if bacEstimate.bac <= 0 {
            return "You are sober"
        } else if bacEstimate.bac >= Constants.BAC.legalLimit {
            return "Legal to drive in \(bacEstimate.timeUntilLegalFormatted)"
        } else {
            return "Completely sober in \(bacEstimate.timeUntilSoberFormatted)"
        }
    }
}

struct SafetyActionButton: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .contentShape(Rectangle())
    }
}

struct LocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        
        // Initialize region with the coordinate
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [LocationPin(coordinate: coordinate)]) { pin in
            MapMarker(coordinate: pin.coordinate, tint: .blue)
        }
    }
    
    struct LocationPin: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}

struct EmergencyContactsSection: View {
    let contacts: [EmergencyContact]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emergency Contacts")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(contacts) { contact in
                        ContactCard(contact: contact)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ContactCard: View {
    let contact: EmergencyContact
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(initials)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Name
            Text(contact.name)
                .font(.headline)
                .lineLimit(1)
            
            // Primary tag
            if contact.isPrimary {
                Text("Primary")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            // Call button
            Button {
                callContact()
            } label: {
                Text("Call")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
        }
        .padding()
        .frame(width: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    private var initials: String {
        let words = contact.name.components(separatedBy: .whitespacesAndNewlines)
        let letters = words.compactMap { $0.first }
        
        if letters.isEmpty {
            return "?"
        } else if letters.count == 1 {
            return String(letters[0]).uppercased()
        } else {
            return String(letters[0]) + String(letters[1])
        }
    }
    
    private func callContact() {
        guard let url = URL(string: "tel://\(contact.phoneNumber.filter { $0.isNumber })") else { return }
        UIApplication.shared.open(url)
    }
}

struct NoContactsWarning: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("No Emergency Contacts")
                .font(.headline)
            
            Text("Add emergency contacts to enable quick access in case of an emergency.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: EmergencyContactsView()) {
                Text("Add Contacts")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
        .padding(.horizontal)
    }
}

struct SafetyTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.UI.standardPadding) {
                    // Image
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    
                    // Title
                    Text("Alcohol Safety Tips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom)
                    
                    // Introduction
                    Text("Drinking responsibly means taking steps to ensure your safety and the safety of others. Here are some important tips to remember:")
                        .font(.subheadline)
                        .padding(.bottom)
                    
                    // Tips
                    SafetyTipView(
                        title: "Never Drive Under the Influence",
                        description: "Even small amounts of alcohol can impair your ability to drive. Always arrange alternative transportation if you've been drinking.",
                        icon: "car.fill"
                    )
                    
                    SafetyTipView(
                        title: "Stay Hydrated",
                        description: "Drink water between alcoholic beverages to help prevent dehydration and reduce the effects of alcohol.",
                        icon: "drop.fill"
                    )
                    
                    SafetyTipView(
                        title: "Eat Before and While Drinking",
                        description: "Having food in your stomach slows alcohol absorption into your bloodstream.",
                        icon: "fork.knife"
                    )
                    
                    SafetyTipView(
                        title: "Know Your Limits",
                        description: "Understand how alcohol affects you personally and stop drinking before reaching your limit.",
                        icon: "gauge"
                    )
                    
                    SafetyTipView(
                        title: "Watch Your Drinks",
                        description: "Never leave your drink unattended to prevent someone from tampering with it.",
                        icon: "eye.fill"
                    )
                    
                    SafetyTipView(
                        title: "Use the Buddy System",
                        description: "Stay with friends and look out for each other when drinking in public places.",
                        icon: "person.2.fill"
                    )
                    
                    SafetyTipView(
                        title: "Plan Ahead",
                        description: "Before going out, plan how you'll get home safely whether it's a designated driver, rideshare, or public transportation.",
                        icon: "map.fill"
                    )
                    
                    // Disclaimer
                    Text("Remember: The only truly safe amount of alcohol to consume before driving is zero. Always prioritize safety over convenience.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Safety Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SafetyTipView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

struct SafetyToolsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SafetyToolsView()
                .environmentObject(UserViewModel())
                .environmentObject(BACViewModel())
                .environmentObject({
                    let viewModel = EmergencyViewModel()
                    viewModel.contacts = [
                        EmergencyContact.example,
                        EmergencyContact(
                            userId: "example",
                            name: "John Smith",
                            phoneNumber: "5551234567"
                        )
                    ]
                    return viewModel
                }())
        }
    }
}
