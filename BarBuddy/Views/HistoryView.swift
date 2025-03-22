//
//  HistoryView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedTimeFrame: TimeFrame = .day
    
    enum TimeFrame: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Time frame selector
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Summary statistics
                DrinkingSummary(drinks: filteredDrinks(), timeFrame: selectedTimeFrame)
                
                // Drink history list
                List {
                    ForEach(drinksByDate.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(formatDate(date))) {
                            ForEach(drinksByDate[date] ?? [], id: \.id) { drink in
                                DrinkHistoryRow(drink: drink)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Drinking History")
        }
    }
    
    // Filter drinks based on selected time frame
    private func filteredDrinks() -> [Drink] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeFrame.days, to: endDate) else {
            return []
        }
        
        return drinkTracker.drinks.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    // Group drinks by date
    private var drinksByDate: [Date: [Drink]] {
        let calendar = Calendar.current
        
        // Group by day
        return Dictionary(grouping: filteredDrinks()) { drink in
            let components = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
            return calendar.date(from: components) ?? Date()
        }
    }
    
    // Format date for section headers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// Summary view showing statistics for the selected time frame
struct DrinkingSummary: View {
    let drinks: [Drink]
    let timeFrame: HistoryView.TimeFrame
    
    var totalDrinks: Int {
        return drinks.count
    }
    
    var totalStandardDrinks: Double {
        return drinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    var averageDrinksPerDay: Double {
        guard timeFrame.days > 0 else { return 0 }
        return Double(totalDrinks) / Double(timeFrame.days)
    }
    
    var maxBACReached: Double {
        // This is a simplification - would need proper BAC calculation for accuracy
        return drinks.reduce(0) { max($0, $1.standardDrinks * 0.02) }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Summary for Last \(timeFrame.rawValue)")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatisticView(
                    value: String(totalDrinks),
                    label: "Total\nDrinks",
                    systemImage: "drop.fill"
                )
                
                StatisticView(
                    value: String(format: "%.1f", totalStandardDrinks),
                    label: "Standard\nDrinks",
                    systemImage: "wineglass"
                )
                
                StatisticView(
                    value: String(format: "%.1f", averageDrinksPerDay),
                    label: "Daily\nAverage",
                    systemImage: "calendar"
                )
            }
            
            // BAC history graph would go here
            // This is a placeholder for where you would add a proper chart
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    Text("BAC History Graph")
                        .foregroundColor(.secondary)
                )
                .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}

// Single statistic view
struct StatisticView: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(minWidth: 70)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Row for a single drink in history
struct DrinkHistoryRow: View {
    let drink: Drink
    
    var body: some View {
        HStack {
            Text(drink.type.icon)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(drink.type.rawValue)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", drink.size)) oz, \(String(format: "%.1f", drink.alcoholPercentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(formatTime(drink.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", drink.standardDrinks)) standard")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environmentObject(DrinkTracker())
    }
}
