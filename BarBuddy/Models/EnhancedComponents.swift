//
//  EnhancedComponents.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
import SwiftUI

// MARK: - Enhanced Feature Row
struct EnhancedFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.accent)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Enhanced BAC Status Card
// Create this in your EnhancedComponents.swift file
struct EnhancedBACStatusCard: View {
    let bac: Double
    let timeUntilSober: TimeInterval
    
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
        case .safe: return .safe
        case .borderline: return .warning
        case .unsafe: return .danger
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main BAC display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BAC")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.3f", bac))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                if timeUntilSober > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SOBER IN")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        
                        Text(formatTimeUntilSober(timeUntilSober))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(statusColor)
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground)
            
            // Status banner
            HStack {
                Image(systemName: safetyStatusIcon)
                    .foregroundColor(.white)
                
                Text(safetyStatus.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(statusColor)
        }
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private var safetyStatusIcon: String {
        switch safetyStatus {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
    
    private func formatTimeUntilSober(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - Enhanced Quick Action Button
struct EnhancedQuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Enhanced Drink Card
struct EnhancedDrinkCard: View {
    let drinkType: DrinkType
    let size: Double
    let alcoholPercentage: Double
    let action: () -> Void
    
    var drinkTypeGradient: LinearGradient {
        switch drinkType {
        case .beer:
            return LinearGradient(gradient: Gradient(colors: [Color.beerColor, Color.beerColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .wine:
            return LinearGradient(gradient: Gradient(colors: [Color.wineColor, Color.wineColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .cocktail:
            return LinearGradient(gradient: Gradient(colors: [Color.cocktailColor, Color.cocktailColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .shot:
            return LinearGradient(gradient: Gradient(colors: [Color.shotColor, Color.shotColor.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .other:
            return LinearGradient(gradient: Gradient(colors: [Color.appTextSecondary, Color.appTextSecondary.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Text(drinkType.icon)
                    .font(.system(size: 28))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drinkType.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(String(format: "%.1f", size))oz, \(String(format: "%.1f", alcoholPercentage))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(drinkTypeGradient)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Drink History Row
struct EnhancedDrinkHistoryRow: View {
    let drink: Drink
    
    var drinkTypeColor: Color {
        switch drink.type {
        case .beer: return .beerColor
        case .wine: return .wineColor
        case .cocktail: return .cocktailColor
        case .shot: return .shotColor
        case .other: return .appTextSecondary
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(drinkTypeColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(drink.type.icon)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextPrimary)
                
                Text("\(String(format: "%.1f", drink.size)) oz, \(String(format: "%.1f", drink.alcoholPercentage))%")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(drink.timestamp))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                
                HStack(spacing: 2) {
                    Image(systemName: "wineglass")
                        .font(.system(size: 10))
                    Text("\(String(format: "%.1f", drink.standardDrinks))")
                        .font(.caption)
                }
                .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.vertical, 10)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
    
    @ViewBuilder
    private var enhancedSidebarContent: some View {
        List {
            NavigationLink(destination: EnhancedDashboardView().navigationTitle("Dashboard")) {
                Label("Dashboard", systemImage: "gauge")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: EnhancedDrinkLogView().navigationTitle("Log Drink")) {
                Label("Log Drink", systemImage: "plus.circle")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: EnhancedHistoryView().navigationTitle("History")) {
                Label("History", systemImage: "clock")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: EnhancedShareView().navigationTitle("Share")) {
                Label("Share", systemImage: "person.2")
                    .foregroundColor(.appTextPrimary)
            }
            
            NavigationLink(destination: EnhancedSettingsView().navigationTitle("Settings")) {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(.appTextPrimary)
            }
        }
        .listStyle(SidebarListStyle())
        .accentColor(Color.accent)
    }
    
    @ViewBuilder
    private func enhancedSelectedTabView() -> some View {
        switch selectedTab {
        case 0:
            EnhancedDashboardView()
                .navigationTitle("Dashboard")
        case 1:
            EnhancedDrinkLogView()
                .navigationTitle("Log Drink")
        case 2:
            EnhancedHistoryView()
                .navigationTitle("History")
        case 3:
            EnhancedShareView()
                .navigationTitle("Share")
        case 4:
            EnhancedSettingsView()
                .navigationTitle("Settings")
        default:
            EnhancedDashboardView()
                .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Enhanced Dashboard View
struct EnhancedDashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingRideshareOptions = false
    @State private var showingEmergencyContact = false
    @State private var showingQuickAdd = false
    @State private var expandedSection: DashboardSection? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    enum DashboardSection {
        case bac, drinks, safeTips
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // BAC Status Card
                EnhancedBACStatusCard(
                    bac: drinkTracker.currentBAC,
                    timeUntilSober: drinkTracker.timeUntilSober
                )
                .padding(.horizontal)
                
                // Quick Action Buttons
                HStack(spacing: 15) {
                    EnhancedQuickActionButton(
                        title: "Quick Add",
                        systemImage: "plus.circle.fill",
                        color: .accent,
                        action: { showingQuickAdd = true }
                    )
                    
                    EnhancedQuickActionButton(
                        title: "Get Ride",
                        systemImage: "car.fill",
                        color: .safe,
                        action: { showingRideshareOptions = true }
                    )
                    
                    EnhancedQuickActionButton(
                        title: "Emergency",
                        systemImage: "exclamationmark.triangle.fill",
                        color: .danger,
                        action: { showingEmergencyContact = true }
                    )
                }
                .padding(.horizontal)
                
                // Recent Drinks Summary
                EnhancedRecentDrinksSummary(
                    drinks: drinkTracker.drinks,
                    onRemove: { drink in drinkTracker.removeDrink(drink) }
                )
                .padding(.horizontal)
                
                // Quick BAC Share button
                if drinkTracker.currentBAC > 0 {
                    EnhancedQuickShareButton(bac: drinkTracker.currentBAC)
                        .padding(.horizontal)
                }
                
                // Safety Tips
                EnhancedSafetyTipsView(bac: drinkTracker.currentBAC)
                    .padding(.horizontal)
                
                // Drink Suggestions
                if drinkTracker.currentBAC > 0 {
                    EnhancedDrinkSuggestionView()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showingQuickAdd) {
            EnhancedQuickAddDrinkSheet()
        }
        .sheet(isPresented: $showingRideshareOptions) {
            EnhancedRideshareOptionsView()
        }
        .actionSheet(isPresented: $showingEmergencyContact) {
            ActionSheet(
                title: Text("Emergency Options"),
                message: Text("What do you need help with?"),
                buttons: [
                    .default(Text("Call Emergency Contact")) {
                        if let contact = EmergencyContactManager.shared.emergencyContacts.first {
                            EmergencyContactManager.shared.callEmergencyContact(contact)
                        }
                    },
                    .default(Text("Get a Ride")) {
                        showingRideshareOptions = true
                    },
                    .destructive(Text("Call 911")) {
                        if let url = URL(string: "tel://911") {
                            UIApplication.shared.open(url)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Enhanced Recent Drinks Summary
struct EnhancedRecentDrinksSummary: View {
    let drinks: [Drink]
    let onRemove: (Drink) -> Void
    @State private var isExpanded: Bool = false
    
    var recentDrinks: [Drink] {
        // Get drinks from the last 24 hours
        return drinks.filter {
            Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    var totalStandardDrinks: Double {
        return recentDrinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Recent Drinks")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    Spacer()
                    
                    Text("\(recentDrinks.count) drinks today")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.appTextSecondary)
                        .font(.caption)
                        .padding(8)
                        .background(Color.appBackground.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.appCardBackground)
            }
            .buttonStyle(PlainButtonStyle())
            
            if recentDrinks.isEmpty {
                Text("No drinks recorded in the last 24 hours")
                    .foregroundColor(.appTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appCardBackground)
            } else {
                // Summary statistics
                HStack(spacing: 0) {
                    EnhancedStatisticView(
                        title: "Total Drinks",
                        value: "\(recentDrinks.count)",
                        icon: "drop.fill"
                    )
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    EnhancedStatisticView(
                        title: "Standard Drinks",
                        value: String(format: "%.1f", totalStandardDrinks),
                        icon: "wineglass"
                    )
                    
                    if !isExpanded {
                        Divider()
                            .padding(.vertical, 10)
                        
                        EnhancedStatisticView(
                            title: "Last Drink",
                            value: recentDrinks.first != nil ? timeAgo(recentDrinks.first!.timestamp) : "-",
                            icon: "clock"
                        )
                    }
                }
                .padding(.vertical, 10)
                .background(Color.appCardBackground)
                
                if isExpanded {
                    // Detailed list of recent drinks
                    VStack(spacing: 0) {
                        ForEach(recentDrinks.prefix(5)) { drink in
                            EnhancedDrinkHistoryRow(drink: drink)
                                .padding(.horizontal)
                            
                            if drink.id != recentDrinks.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                        
                        if recentDrinks.count > 5 {
                            Button(action: {
                                // Navigate to full history view
                            }) {
                                Text("View All \(recentDrinks.count) Drinks")
                                    .font(.subheadline)
                                    .foregroundColor(.accent)
                                    .padding()
                            }
                        }
                    }
                    .background(Color.appCardBackground)
                }
            }
        }
        .background(Color.appCardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Enhanced Statistic View
struct EnhancedStatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.accent)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.appTextPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Safety Tips View
struct EnhancedSafetyTipsView: View {
    let bac: Double
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Safety Tips")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.appTextSecondary)
                        .font(.caption)
                        .padding(8)
                        .background(Color.appBackground.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.appCardBackground)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warning)
                    .padding(.trailing, 5)
                
                Text(quickTip)
                    .font(.subheadline)
                    .foregroundColor(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.warningBackground)
            
            if isExpanded {
                // Extended tips
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(safetyTips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.safe)
                                .padding(.top, 2)
                            
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.appTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color.appCardBackground)
            }
        }
        .background(Color.appCardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    var quickTip: String {
        if bac >= 0.08 {
            return "Your BAC is above the legal limit. DO NOT drive and consider switching to water."
        } else if bac >= 0.04 {
            return "Remember to alternate alcoholic drinks with water to stay hydrated."
        } else if bac > 0 {
            return "Drinking on an empty stomach speeds up alcohol absorption. Consider eating something."
        } else {
            return "Pace yourself by having no more than one standard drink per hour."
        }
    }
    
    var safetyTips: [String] {
        [
            "Drink water before, during, and after consuming alcohol to stay hydrated.",
            "Always arrange for a safe ride home before you start drinking.",
            "Eat a meal before drinking to slow alcohol absorption.",
            "Know your limits and stick to them.",
            "Check in with trusted friends or family members periodically.",
            "Remember that coffee doesn't sober you up - only time can reduce BAC."
        ]
    }
}

// MARK: - Enhanced Quick Share Button
struct EnhancedQuickShareButton: View {
    let bac: Double
    @State private var showingShareOptions = false
    
    var body: some View {
        Button(action: {
            showingShareOptions = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                Text("Share My Status")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.safe, Color.safe.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(30)
            .shadow(color: Color.safe.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .sheet(isPresented: $showingShareOptions) {
            EnhancedShareView()
        }
    }
}

// MARK: - Enhanced Quick Add Drink Sheet
struct EnhancedQuickAddDrinkSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedDrinkType: DrinkType = .beer
    @State private var size: Double = 12.0
    @State private var alcoholPercentage: Double = 5.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Drink type selector
                    VStack(alignment: .leading, spacing: 15) {
                        Text("DRINK TYPE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(DrinkType.allCases, id: \.self) { type in
                                    EnhancedDrinkTypeButton(
                                        drinkType: type,
                                        isSelected: selectedDrinkType == type,
                                        action: {
                                            selectedDrinkType = type
                                            size = type.defaultSize
                                            alcoholPercentage = type.defaultAlcoholPercentage
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Size selector
                    VStack(alignment: .leading, spacing: 15) {
                        Text("SIZE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(String(format: "%.1f", size)) oz")
                                    .font(.headline)
                                    .foregroundColor(.appTextPrimary)
                                    .frame(width: 70, alignment: .leading)
                                
                                Spacer()
                                
                                // Quick preset buttons
                                EnhancedSizePresetRow(size: $size)
                            }
                            
                            Slider(value: $size, in: 1...24, step: 0.5)
                                .accentColor(Color.accent)
                            
                            // Size visualization
                            EnhancedSizeVisualization(size: size, drinkType: selectedDrinkType)
                                .frame(height: 80)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Alcohol percentage selector
                    VStack(alignment: .leading, spacing: 15) {
                        Text("ALCOHOL PERCENTAGE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(String(format: "%.1f", alcoholPercentage))%")
                                    .font(.headline)
                                    .foregroundColor(.appTextPrimary)
                                    .frame(width: 70, alignment: .leading)
                                
                                Spacer()
                                
                                // Quick preset buttons
                                EnhancedPercentagePresetRow(percentage: $alcoholPercentage)
                            }
                            
                            Slider(value: $alcoholPercentage, in: 0.5...70, step: 0.5)
                                .accentColor(Color.accent)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Standard drinks equivalent
                    VStack(alignment: .leading, spacing: 15) {
                        Text("EQUIVALENT TO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.accent)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Standard Drinks:")
                                    .font(.subheadline)
                                    .foregroundColor(.appTextSecondary)
                                
                                Text(String(format: "%.1f", calculateStandardDrinks()))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appTextPrimary)
                            }
                            
                            Spacer()
                            
                            // Visual representation
                            HStack(spacing: 2) {
                                ForEach(0..<min(Int(calculateStandardDrinks() * 2), 10), id: \.self) { _ in
                                    Image(systemName: "wineglass.fill")
                                        .foregroundColor(.accent)
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Add drink button
                    Button(action: addDrink) {
                        Text("Add Drink")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(30)
                            .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Add Drink")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func calculateStandardDrinks() -> Double {
        // A standard drink is defined as 0.6 fl oz of pure alcohol
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
    
    private func addDrink() {
        drinkTracker.addDrink(
            type: selectedDrinkType,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
        
        // Give haptic feedback for successful addition
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Enhanced Drink Type Button
struct EnhancedDrinkTypeButton: View {
    let drinkType: DrinkType
    let isSelected: Bool
    let action: () -> Void
    
    var drinkTypeColor: Color {
        switch drinkType {
        case .beer: return .beerColor
        case .wine: return .wineColor
        case .cocktail: return .cocktailColor
        case .shot: return .shotColor
        case .other: return .appTextSecondary
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? drinkTypeColor : Color.appCardBackground)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? drinkTypeColor : Color.appSeparator, lineWidth: 2)
                        )
                    
                    Text(drinkType.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : drinkTypeColor)
                }
                
                Text(drinkType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? drinkTypeColor : .appTextPrimary)
            }
            .frame(width: 75)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Size Preset Row
struct EnhancedSizePresetRow: View {
    @Binding var size: Double
    
    let presets: [Double] = [1.5, 5.0, 8.0, 12.0, 16.0]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                Button(action: {
                    size = preset
                }) {
                    Text("\(Int(preset))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(size == preset ? Color.accent : Color.appBackground)
                        .foregroundColor(size == preset ? .white : .appTextPrimary)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Enhanced Percentage Preset Row
struct EnhancedPercentagePresetRow: View {
    @Binding var percentage: Double
    
    let presets: [Double] = [5.0, 12.0, 15.0, 40.0]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                Button(action: {
                    percentage = preset
                }) {
                    Text("\(Int(preset))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(percentage == preset ? Color.accent : Color.appBackground)
                        .foregroundColor(percentage == preset ? .white : .appTextPrimary)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Enhanced Size Visualization
struct EnhancedSizeVisualization: View {
    let size: Double
    let drinkType: DrinkType
    
    var drinkTypeColor: Color {
        switch drinkType {
        case .beer: return .beerColor
        case .wine: return .wineColor
        case .cocktail: return .cocktailColor
        case .shot: return .shotColor
        case .other: return .appTextSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Container visualization
            ZStack(alignment: .bottom) {
                // Container
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appSeparator, lineWidth: 2)
                    .frame(width: 50, height: 80)
                
                // Liquid fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(drinkTypeColor.opacity(0.7))
                    .frame(width: 46, height: min(size / 20 * 80, 76))
                    .padding(.bottom, 2)
            }
            
            // Size reference text
            VStack(alignment: .leading, spacing: 5) {
                Text("Size reference:")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                
                if drinkType == .beer {
                    Text("Standard can: 12 oz")
                        .font(.caption)
                        .foregroundColor(.appTextPrimary)
                } else if drinkType == .wine {
                    Text("Standard pour: 5 oz")
                        .font(.caption)
                        .foregroundColor(.appTextPrimary)
                } else if drinkType == .shot {
                    Text("Standard shot: 1.5 oz")
                        .font(.caption)
                        .foregroundColor(.appTextPrimary)
                } else if drinkType == .cocktail {
                    Text("Standard cocktail: 4-6 oz")
                        .font(.caption)
                        .foregroundColor(.appTextPrimary)
                }
                                        
                if size > 20 {
                    Text("⚠️ Large size")
                        .font(.caption)
                        .foregroundColor(.warning)
                        }
                    }
                                    
                Spacer()
            }
        }
    }

                        // MARK: - Enhanced Drink Log View
                        struct EnhancedDrinkLogView: View {
                            @EnvironmentObject private var drinkTracker: DrinkTracker
                            @State private var showingCustomDrinkView = false
                            @State private var showingQuickAddConfirmation = false
                            @State private var lastAddedDrink: DrinkType?
                            @State private var showHistoryChart = true
                            @State private var confirmationTimer: Timer?
                            @Environment(\.horizontalSizeClass) var horizontalSizeClass
                            
                            var body: some View {
                                ScrollView {
                                    VStack(spacing: 20) {
                                        // Current BAC display
                                        EnhancedBACStatusCard(
                                            bac: drinkTracker.currentBAC,
                                            timeUntilSober: drinkTracker.timeUntilSober
                                        )
                                        .padding(.horizontal)
                                        
                                        // Quick Add Section
                                        VStack(spacing: 15) {
                                            HStack {
                                                Text("Quick Add")
                                                    .font(.headline)
                                                    .foregroundColor(.appTextPrimary)
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    withAnimation {
                                                        showHistoryChart.toggle()
                                                    }
                                                }) {
                                                    Label(showHistoryChart ? "Hide Chart" : "Show Chart",
                                                          systemImage: showHistoryChart ? "chart.bar.xaxis" : "chart.bar")
                                                    .font(.caption)
                                                    .foregroundColor(.accent)
                                                }
                                            }
                                            .padding(.horizontal)
                                            
                                            // Toast-style confirmation message
                                            if showingQuickAddConfirmation, let drink = lastAddedDrink {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.safe)
                                                    Text("\(drink.rawValue) added")
                                                        .font(.subheadline)
                                                        .foregroundColor(.appTextPrimary)
                                                    Spacer()
                                                }
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 15)
                                                .background(Color.safeBackground)
                                                .cornerRadius(10)
                                                .padding(.horizontal)
                                                .transition(.opacity.combined(with: .move(edge: .top)))
                                            }
                                            
                                            // Drink history chart
                                            if showHistoryChart {
                                                EnhancedDrinkHistoryChart(drinks: drinkTracker.drinks)
                                                    .frame(height: 180)
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 10)
                                            }
                                            
                                            // Quick add drink buttons grid
                                            LazyVGrid(columns: [
                                                GridItem(.flexible()),
                                                GridItem(.flexible())
                                            ], spacing: 15) {
                                                ForEach(DrinkType.allCases, id: \.self) { drinkType in
                                                    EnhancedDrinkCard(
                                                        drinkType: drinkType,
                                                        size: drinkType.defaultSize,
                                                        alcoholPercentage: drinkType.defaultAlcoholPercentage,
                                                        action: { addDefaultDrink(type: drinkType) }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                        .padding(.vertical, 15)
                                        .background(Color.appCardBackground)
                                        .cornerRadius(15)
                                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                        .padding(.horizontal)
                                        
                                        // Custom Drink Button
                                        Button(action: { showingCustomDrinkView = true }) {
                                            HStack {
                                                Image(systemName: "slider.horizontal.3")
                                                    .font(.system(size: 16))
                                                Text("Custom Drink")
                                                    .font(.headline)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing)
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                            .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
                                        }
                                        .padding(.horizontal)
                                        
                                        // Recently Added Drinks
                                        EnhancedRecentDrinksSummary(
                                            drinks: drinkTracker.drinks,
                                            onRemove: { drink in
                                                drinkTracker.removeDrink(drink)
                                            }
                                        )
                                        .padding(.horizontal)
                                    }
                                    .padding(.vertical)
                                }
                                .background(Color.appBackground)
                                .navigationTitle("Log Drink")
                                .sheet(isPresented: $showingCustomDrinkView) {
                                    EnhancedQuickAddDrinkSheet()
                                }
                                .onDisappear {
                                    confirmationTimer?.invalidate()
                                }
                            }
                            
                            private func addDefaultDrink(type: DrinkType) {
                                drinkTracker.addDrink(
                                    type: type,
                                    size: type.defaultSize,
                                    alcoholPercentage: type.defaultAlcoholPercentage
                                )
                                
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                lastAddedDrink = type
                                showingQuickAddConfirmation = true
                                
                                confirmationTimer?.invalidate()
                                confirmationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                                    withAnimation {
                                        showingQuickAddConfirmation = false
                                    }
                                }
                                
                                WatchSessionManager.shared.sendBACDataToWatch(
                                    bac: drinkTracker.currentBAC,
                                    timeUntilSober: drinkTracker.timeUntilSober
                                )
                            }
                        }

                        // MARK: - Enhanced Drink History Chart
                        struct EnhancedDrinkHistoryChart: View {
                            let drinks: [Drink]
                            
                            var recentDrinks: [Drink] {
                                let calendar = Calendar.current
                                let startOfToday = calendar.startOfDay(for: Date())
                                
                                return drinks.filter {
                                    $0.timestamp >= startOfToday
                                }
                                .sorted { $0.timestamp < $1.timestamp }
                            }
                            
                            var hourlyData: [HourlyDrink] {
                                let calendar = Calendar.current
                                let startOfToday = calendar.startOfDay(for: Date())
                                
                                // Create a dictionary to hold drinks per hour
                                var hourlyDrinks: [Int: Double] = [:]
                                
                                // Count standard drinks per hour
                                for drink in recentDrinks {
                                    let hourComponent = calendar.component(.hour, from: drink.timestamp)
                                    hourlyDrinks[hourComponent, default: 0] += drink.standardDrinks
                                }
                                
                                // Convert to array for chart
                                var result: [HourlyDrink] = []
                                for hour in 0..<24 {
                                    let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfToday)!
                                    result.append(HourlyDrink(
                                        hour: hour,
                                        date: hourDate,
                                        standardDrinks: hourlyDrinks[hour, default: 0]
                                    ))
                                }
                                
                                return result
                            }
                            
                            var body: some View {
                                if #available(iOS 16.0, *) {
                                    // Use Swift Charts if available, but implementation will depend on iOS version
                                    // This is a placeholder for where SwiftUI's Chart would go
                                    BarChart(data: hourlyData)
                                } else {
                                    // Fallback for iOS 15
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("Today's Drinks:")
                                            .font(.caption)
                                            .foregroundColor(.appTextSecondary)
                                        
                                        HStack(alignment: .bottom, spacing: 4) {
                                            ForEach(hourlyData.indices, id: \.self) { index in
                                                if index % 2 == 0 { // Only show every other hour to save space
                                                    let hourData = hourlyData[index]
                                                    VStack {
                                                        Rectangle()
                                                            .fill(Color.accent)
                                                            .frame(width: 8, height: max(hourData.standardDrinks * 20, 1))
                                                        
                                                        if index % 4 == 0 { // Only show every 4 hours
                                                            Text("\(hourData.hour)")
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.appTextSecondary)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .frame(height: 100)
                                        .overlay(
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(.appSeparator)
                                                .offset(y: -40),
                                            alignment: .bottom
                                        )
                                    }
                                }
                            }
                            
                            struct HourlyDrink: Identifiable {
                                let id = UUID()
                                let hour: Int
                                let date: Date
                                let standardDrinks: Double
                            }
                        }

                        // MARK: - Enhanced Bar Chart (for iOS 15 compatibility)
                        struct BarChart: View {
                            let data: [EnhancedDrinkHistoryChart.HourlyDrink]
                            
                            var maxValue: Double {
                                return data.map { $0.standardDrinks }.max() ?? 1.0
                            }
                            
                            var body: some View {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Chart title
                                    Text("Standard Drinks by Hour")
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                    
                                    // Y-axis max value
                                    HStack {
                                        Text(String(format: "%.1f", maxValue))
                                            .font(.system(size: 8))
                                            .foregroundColor(.appTextSecondary)
                                        
                                        Spacer()
                                    }
                                    
                                    // Chart
                                    HStack(alignment: .bottom, spacing: 2) {
                                        // Y-axis
                                        VStack(alignment: .trailing, spacing: 0) {
                                            ForEach([0.75, 0.5, 0.25, 0], id: \.self) { level in
                                                Text(String(format: "%.1f", maxValue * level))
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.appTextSecondary)
                                                    .frame(height: 20)
                                            }
                                        }
                                        .frame(width: 20)
                                        
                                        // Bars
                                        HStack(alignment: .bottom, spacing: 2) {
                                            ForEach(data.indices, id: \.self) { index in
                                                if index % 2 == 0 { // Only display every other hour to save space
                                                    let item = data[index]
                                                    VStack(spacing: 2) {
                                                        Rectangle()
                                                            .fill(Color.accent)
                                                            .frame(width: 6, height: max(item.standardDrinks / maxValue * 80, 1))
                                                        
                                                        if index % 4 == 0 { // Only label every 4 hours
                                                            Text("\(item.hour)")
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.appTextSecondary)
                                                        } else {
                                                            Text("")
                                                                .font(.system(size: 8))
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Recommended limit line
                                    HStack {
                                        Text("Recommended daily limit: 4 standard drinks")
                                            .font(.system(size: 8))
                                            .foregroundColor(.warning)
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(10)
                            }
                        }

                        // MARK: - Enhanced Rideshare Options View
                        struct EnhancedRideshareOptionsView: View {
                            @Environment(\.presentationMode) var presentationMode
                            @State private var isProcessing = false
                            
                            var body: some View {
                                NavigationView {
                                    VStack(spacing: 20) {
                                        Text("Get a Safe Ride Home")
                                            .font(.headline)
                                            .padding(.top, 20)
                                        
                                        if isProcessing {
                                            ProgressView()
                                                .padding()
                                        } else {
                                            // Uber Button
                                            Button(action: {
                                                requestRide(service: "uber")
                                            }) {
                                                HStack(spacing: 15) {
                                                    Image(systemName: "car.fill")
                                                        .font(.title3)
                                                    Text("Uber")
                                                        .font(.title3)
                                                        .fontWeight(.semibold)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .cornerRadius(15)
                                            }
                                            .padding(.horizontal)
                                            
                                            // Lyft Button
                                            Button(action: {
                                                requestRide(service: "lyft")
                                            }) {
                                                HStack(spacing: 15) {
                                                    Image(systemName: "car.fill")
                                                        .font(.title3)
                                                    Text("Lyft")
                                                        .font(.title3)
                                                        .fontWeight(.semibold)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.pink)
                                                .foregroundColor(.white)
                                                .cornerRadius(15)
                                            }
                                            .padding(.horizontal)
                                            
                                            // Cancel Button
                                            Button(action: {
                                                presentationMode.wrappedValue.dismiss()
                                            }) {
                                                Text("Cancel")
                                                    .foregroundColor(.accent)
                                                    .padding(.vertical, 15)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.appBackground)
                                    .navigationTitle("Get a Ride")
                                    .navigationBarTitleDisplayMode(.inline)
                                }
                            }
                            
                            private func requestRide(service: String) {
                                isProcessing = true
                                
                                // Open the app if installed, or website if not
                                let appUrlScheme = service == "uber" ? "uber://" : "lyft://"
                                if let url = URL(string: appUrlScheme) {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                        presentationMode.wrappedValue.dismiss()
                                        return
                                    } else if let webUrl = URL(string: service == "uber" ? "https://m.uber.com" : "https://www.lyft.com") {
                                        UIApplication.shared.open(webUrl)
                                        presentationMode.wrappedValue.dismiss()
                                        return
                                    }
                                }
                                
                                // If we couldn't open the app or website, finish processing
                                isProcessing = false
                            }
                        }

                        // MARK: - Enhanced Share View
struct EnhancedShareView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @StateObject private var shareManager = ShareManager()
    @State private var messageDelegate = ShareViewMessageDelegate()
    @State private var selectedContacts: [Contact] = []
    @State private var customMessage: String = "Here's my current BAC."
    @State private var shareExpiration: Double = 2.0
    @State private var includeLocation = false
    @State private var showingShareOptions = false
    @State private var showingQRCode = false
    @State private var selectedShareOption: ShareOption = .text
    @State private var showingSavedShares = false
    @State private var showingMessageComposer = false
    
    enum ShareOption {
        case text, email, qrCode, url
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current BAC display
                VStack(spacing: 8) {
                    Text("Current BAC")
                        .font(.headline)
                        .foregroundColor(.appTextSecondary)
                    
                    Text(String(format: "%.3f", drinkTracker.currentBAC))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(statusColor)
                    
                    Text(safetyStatus.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(20)
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                if drinkTracker.currentBAC <= 0.0 {
                    // No BAC to share
                    VStack(spacing: 20) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 70))
                            .foregroundColor(.appTextSecondary.opacity(0.5))
                        
                        Text("No BAC to Share")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appTextPrimary)
                        
                        Text("Log a drink first to share your BAC status with friends.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.appTextSecondary)
                            .padding(.horizontal)
                    }
                    .padding(30)
                    .background(Color.appCardBackground)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                } else {
                    // Active shares
                    if !shareManager.activeShares.isEmpty {
                        Button(action: {
                            showingSavedShares = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.accent)
                                Text("\(shareManager.activeShares.count) Active Shares")
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Share content
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Share Message")
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                            .padding(.horizontal)
                        
                        // Updated message composer button
                        Button(action: {
                            showingMessageComposer = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.white)
                                Text("Compose Message")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(30)
                            .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
                        }
                        .padding(.horizontal)
                        
                        // Message templates
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TEMPLATES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accent)
                                .padding(.leading, 15)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(shareManager.messageTemplates, id: \.self) { template in
                                        Button(action: {
                                            customMessage = template
                                        }) {
                                            Text(template)
                                                .font(.subheadline)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(customMessage == template ? Color.accent : Color.appBackground)
                                                )
                                                .foregroundColor(customMessage == template ? .white : .appTextPrimary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // Location toggle
                        VStack(alignment: .leading, spacing: 5) {
                            Toggle(isOn: $includeLocation) {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.accent)
                                    Text("Include my current location")
                                        .foregroundColor(.appTextPrimary)
                                }
                            }
                            .padding(.horizontal)
                            
                            if includeLocation {
                                Text("Your approximate location will be shared with your BAC status")
                                    .font(.caption)
                                    .foregroundColor(.appTextSecondary)
                                    .padding(.leading, 36)
                                    .padding(.trailing)
                            }
                        }
                        
                        // Share duration
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SHARE WILL EXPIRE AFTER:")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accent)
                                .padding(.leading, 15)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("\(Int(shareExpiration)) hours")
                                        .font(.headline)
                                        .foregroundColor(.appTextPrimary)
                                    
                                    Spacer()
                                    
                                    Text(expirationTimeString(hours: shareExpiration))
                                        .font(.caption)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Slider(value: $shareExpiration, in: 1...24, step: 1)
                                    .accentColor(.accent)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Share buttons
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SHARE OPTIONS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accent)
                                .padding(.leading, 15)
                                .padding(.top, 5)
                            
                            HStack(spacing: 10) {
                                EnhancedShareOptionButton(
                                    title: "Text",
                                    systemImage: "message.fill",
                                    color: .green,
                                    isSelected: selectedShareOption == .text,
                                    action: {
                                        selectedShareOption = .text
                                        showingShareOptions = true
                                    }
                                )
                                
                                EnhancedShareOptionButton(
                                    title: "Email",
                                    systemImage: "envelope.fill",
                                    color: .blue,
                                    isSelected: selectedShareOption == .email,
                                    action: {
                                        selectedShareOption = .email
                                        showingShareOptions = true
                                    }
                                )
                                
                                EnhancedShareOptionButton(
                                    title: "QR Code",
                                    systemImage: "qrcode",
                                    color: .purple,
                                    isSelected: selectedShareOption == .qrCode,
                                    action: {
                                        selectedShareOption = .qrCode
                                        showingQRCode = true
                                    }
                                )
                                
                                EnhancedShareOptionButton(
                                    title: "Link",
                                    systemImage: "link",
                                    color: .orange,
                                    isSelected: selectedShareOption == .url,
                                    action: {
                                        selectedShareOption = .url
                                        shareViaLink()
                                    }
                                )
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                    }
                    .padding(.vertical, 10)
                    .background(Color.appCardBackground)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Emergency contacts section
                    if !EmergencyContactManager.shared.emergencyContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("QUICK SHARE WITH EMERGENCY CONTACTS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accent)
                                .padding(.leading, 15)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(EmergencyContactManager.shared.emergencyContacts) { contact in
                                        Button(action: {
                                            shareWithEmergencyContact(contact)
                                        }) {
                                            VStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.accent.opacity(0.1))
                                                        .frame(width: 60, height: 60)
                                                    
                                                    Text(getInitials(from: contact.name))
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.accent)
                                                }
                                                
                                                Text(contact.name.split(separator: " ").first?.description ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.appTextPrimary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(Color.appCardBackground)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .background(Color.appBackground)
            .navigationTitle("Share Status")
            .sheet(isPresented: $showingShareOptions) {
                switch selectedShareOption {
                case .text:
                    EnhancedContactSelectionView(
                        shareManager: shareManager,
                        selectedContacts: $selectedContacts,
                        onShare: { contacts in
                            shareViaText(with: contacts)
                        }
                    )
                case .email:
                    EnhancedEmailShareView(
                        bac: drinkTracker.currentBAC,
                        message: customMessage,
                        timeUntilSober: drinkTracker.timeUntilSober,
                        includeLocation: includeLocation
                    )
                default:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showingQRCode) {
                EnhancedQRCodeShareView(
                    bac: drinkTracker.currentBAC,
                    message: customMessage,
                    timeUntilSober: drinkTracker.timeUntilSober,
                    includeLocation: includeLocation
                )
            }
            .sheet(isPresented: $showingSavedShares) {
                EnhancedActiveSharesView(shareManager: shareManager)
            }
            .sheet(isPresented: $showingMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    let phoneNumbers = selectedContacts.map { $0.phone }
                    MessageComposerView(
                        recipients: phoneNumbers,
                        body: createFullShareMessage(),
                        delegate: messageDelegate
                    )
                } else {
                    Text("SMS services are not available on this device")
                        .padding()
                }
            }
        }
    }
    
    // Format expiration time
    private func expirationTimeString(hours: Double) -> String {
        let expirationDate = Date().addingTimeInterval(hours * 3600)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
    }
}
