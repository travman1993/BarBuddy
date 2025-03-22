//
//  DashboardView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingRideshareOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // BAC Circle Indicator
                    BACIndicator(bac: drinkTracker.currentBAC)
                    
                    // Safety Status
                    SafetyStatusView(bac: drinkTracker.currentBAC)
                    
                    // Time Until Sober
                    if drinkTracker.timeUntilSober > 0 {
                        TimeUntilSoberView(timeInterval: drinkTracker.timeUntilSober)
                    }
                    
                    // Recent Drinks Summary
                    RecentDrinksSummary(drinks: drinkTracker.drinks)
                    
                    // Rideshare Button
                    if drinkTracker.currentBAC >= 0.08 {
                        Button(action: {
                            showingRideshareOptions = true
                        }) {
                            HStack {
                                Image(systemName: "car")
                                Text("Get a Safe Ride Home")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Emergency Contact Button
                    EmergencyContactButton()
                        .padding(.horizontal)
                    
                    // Quick BAC Share
                    if drinkTracker.currentBAC > 0 {
                        QuickShareButton(bac: drinkTracker.currentBAC)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("BarBuddy")
            .sheet(isPresented: $showingRideshareOptions) {
                RideshareOptionsView()
            }
        }
    }
}

// BAC Circular Indicator
struct BACIndicator: View {
    let bac: Double
    
    var color: Color {
        switch bac {
        case 0..<0.04: return .green
        case 0.04..<0.08: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(bac) * 5, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: bac)
                
                VStack {
                    Text(String(format: "%.3f", bac))
                        .font(.system(size: 48, weight: .bold))
                    
                    Text("BAC")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Blood Alcohol Content")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Safety Status View
struct SafetyStatusView: View {
    let bac: Double
    
    var safetyStatus: SafetyStatus {
        if bac < 0.04 {
            return .safe
        } else if bac < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }
    
    var statusColor: Color {
        switch safetyStatus {
        case .safe: return .green
        case .borderline: return .yellow
        case .unsafe: return .red
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: safetyStatus.systemImage)
                .foregroundColor(statusColor)
            
            Text(safetyStatus.rawValue)
                .font(.headline)
                .foregroundColor(statusColor)
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(10)
    }
}

// Time Until Sober View
struct TimeUntilSoberView: View {
    let timeInterval: TimeInterval
    
    var formattedTime: String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Text("Time Until Legal to Drive")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock")
                Text(formattedTime)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// Recent Drinks Summary
struct RecentDrinksSummary: View {
    let drinks: [Drink]
    
    var recentDrinks: [Drink] {
        // Get drinks from the last 24 hours
        return drinks.filter {
            Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Drinks")
                .font(.headline)
            
            if recentDrinks.isEmpty {
                Text("No drinks in the last 24 hours")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else {
                ForEach(recentDrinks.prefix(3)) { drink in
                    HStack {
                        Text(drink.type.icon)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(drink.type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(String(format: "%.1f", drink.size)) oz, \(String(format: "%.1f", drink.alcoholPercentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(relativeTimeString(for: drink.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                
                if recentDrinks.count > 3 {
                    Text("+ \(recentDrinks.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    func relativeTimeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Emergency Contact Button
struct EmergencyContactButton: View {
    var body: some View {
        Button(action: {
            // Action to contact emergency contact
        }) {
            HStack {
                Image(systemName: "phone.fill")
                Text("Contact Emergency Contact")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// Quick Share Button
struct QuickShareButton: View {
    let bac: Double
    @State private var showingShareOptions = false
    
    var body: some View {
        Button(action: {
            showingShareOptions = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share My Status")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingShareOptions) {
            // Share options view would go here
            Text("Share Options View")
        }
    }
}

// Rideshare Options View
struct RideshareOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Button(action: openUber) {
                    Label("Uber", systemImage: "car.fill")
                }
                
                Button(action: openLyft) {
                    Label("Lyft", systemImage: "car.fill")
                }
                
                Button(action: callTaxi) {
                    Label("Call Taxi", systemImage: "phone.fill")
                }
            }
            .navigationTitle("Get a Safe Ride")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func openUber() {
        if let url = URL(string: "uber://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let webUrl = URL(string: "https://m.uber.com") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
    
    func openLyft() {
        if let url = URL(string: "lyft://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let webUrl = URL(string: "https://www.lyft.com") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
    
    func callTaxi() {
        // This would ideally show local taxi options
        // For now, just dismiss
        presentationMode.wrappedValue.dismiss()
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(DrinkTracker())
    }
}
