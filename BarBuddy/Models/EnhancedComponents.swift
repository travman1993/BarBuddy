//
//  EnhancedComponents.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
import SwiftUI
import MessageUI

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
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Fix for EnhancedBACStatusCard struct
struct EnhancedBACStatusCard: View {
    let bac: Double
    let timeUntilSober: TimeInterval
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
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
    
    var safetyStatusIcon: String {
        switch safetyStatus {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BAC")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.3f", bac))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                if timeUntilSober > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SOBER IN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
            
            if isExpanded {
                VStack(spacing: 15) {
                    if timeUntilSober > 0 {
                        KeyInfoRow(
                            title: "Time until sober",
                            value: formatTimeUntilSober(timeUntilSober),
                            icon: "clock",
                            warning: false
                        )
                    }
                    
                    Button(action: onToggleExpand) {
                        Text("Show Less")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .background(Color.appCardBackground)
            }
        }
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
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
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
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
            return LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .wine:
            return LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .cocktail:
            return LinearGradient(gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .shot:
            return LinearGradient(gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
        case .other:
            return LinearGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
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
        case .beer: return .blue
        case .wine: return .red
        case .cocktail: return .purple
        case .shot: return .orange
        case .other: return .gray
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
                    .foregroundColor(.primary)
                
                Text("\(String(format: "%.1f", drink.size)) oz, \(String(format: "%.1f", drink.alcoholPercentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(drink.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    Image(systemName: "wineglass")
                        .font(.system(size: 10))
                    Text("\(String(format: "%.1f", drink.standardDrinks))")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
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

// MARK: - Enhanced Statistic View
struct EnhancedStatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Drink Type Button
struct EnhancedDrinkTypeButton: View {
    let drinkType: DrinkType
    let isSelected: Bool
    let action: () -> Void
    
    var drinkTypeColor: Color {
        switch drinkType {
        case .beer: return .blue
        case .wine: return .red
        case .cocktail: return .purple
        case .shot: return .orange
        case .other: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? drinkTypeColor : Color(.systemBackground))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? drinkTypeColor : Color.gray.opacity(0.2), lineWidth: 2)
                        )
                    
                    Text(drinkType.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : drinkTypeColor)
                }
                
                Text(drinkType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? drinkTypeColor : .primary)
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
                        .background(size == preset ? Color.blue : Color(.systemBackground))
                        .foregroundColor(size == preset ? .white : .primary)
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
                        .background(percentage == preset ? Color.blue : Color(.systemBackground))
                        .foregroundColor(percentage == preset ? .white : .primary)
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
        case .beer: return .blue
        case .wine: return .red
        case .cocktail: return .purple
        case .shot: return .orange
        case .other: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Container visualization
            ZStack(alignment: .bottom) {
                // Container
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
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
                    .foregroundColor(.secondary)
                
                if drinkType == .beer {
                    Text("Standard can: 12 oz")
                        .font(.caption)
                        .foregroundColor(.primary)
                } else if drinkType == .wine {
                    Text("Standard pour: 5 oz")
                        .font(.caption)
                        .foregroundColor(.primary)
                } else if drinkType == .shot {
                    Text("Standard shot: 1.5 oz")
                        .font(.caption)
                        .foregroundColor(.primary)
                } else if drinkType == .cocktail {
                    Text("Standard cocktail: 4-6 oz")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                                        
                if size > 20 {
                    Text("⚠️ Large size")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
                                    
            Spacer()
        }
    }
}

// This is a simplified placeholder implementation of EnhancedRecentDrinksSummary
// You may need to customize this based on your specific requirements
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
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(recentDrinks.count) drinks today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemBackground).opacity(0.3))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            if recentDrinks.isEmpty {
                Text("No drinks recorded in the last 24 hours")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
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
                .background(Color(.systemBackground))
                
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
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(8)
                        .background(Color(.systemBackground).opacity(0.3))
                        .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Quick tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .padding(.trailing, 5)
                
                Text(quickTip)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.1))
            
            if isExpanded {
                // Extended tips
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(safetyTips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(.top, 2)
                            
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    var quickTip: String {
        if bac >= 0.08 {
            return "Your above the legal limit. DO NOT drive and consider switching to water."
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
                LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(30)
            .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

// MARK: - Placeholder Components
// These are simplified placeholders for components that are referenced but missing implementations
struct EnhancedDrinkSuggestionView: View {
    var body: some View {
        Text("Drink Suggestions")
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
    }
}

struct EnhancedQuickAddDrinkSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Text("Quick Add Drink")
            .navigationTitle("Add Drink")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
    }
}

struct EnhancedRideshareOptionsView: View {
    var body: some View {
        Text("Rideshare Options")
    }
}

struct EnhancedDashboardView: View {
    var body: some View {
        Text("Dashboard View")
    }
}

struct EnhancedDrinkLogView: View {
    var body: some View {
        Text("Drink Log View")
    }
}

struct EnhancedHistoryView: View {
    var body: some View {
        Text("History View")
    }
}

struct EnhancedSettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}

struct EnhancedShareView: View {
    var body: some View {
        Text("Share View")
    }
}

// Helper function for getting initials
func getInitials(from name: String) -> String {
    let components = name.components(separatedBy: " ")
    let firstInitial = components.first?.first?.uppercased() ?? ""
    let lastInitial = components.last?.first?.uppercased() ?? ""
    return firstInitial + (components.count > 1 ? lastInitial : "")
}

// Drink History Chart
struct EnhancedDrinkHistoryChart: View {
    let drinks: [Drink]
    
    var body: some View {
        Text("Drink History Chart")
            .frame(height: 180)
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
}

// Bar Chart (for iOS 15 compatibility)
struct BarChart: View {
    let data: [EnhancedDrinkHistoryChart.HourlyDrink]
    
    var body: some View {
        Text("Bar Chart")
            .frame(height: 180)
            .background(Color(.systemBackground))
            .cornerRadius(10)
    }
}

// Define missing types used in the file
extension EnhancedDrinkHistoryChart {
    struct HourlyDrink: Identifiable {
        let id = UUID()
        let hour: Int
        let date: Date
        let standardDrinks: Double
    }
}
