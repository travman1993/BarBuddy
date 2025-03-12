//
//  HistoryView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    
    @State private var selectedTimeframe = TimeFrame.day
    @State private var isLoading = false
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Timeframe picker
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(TimeFrame.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Stats summary
                    StatsSummaryView(timeframe: selectedTimeframe)
                    
                    // Drink history
                    if drinkViewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if drinkViewModel.recentDrinks.isEmpty {
                        EmptyHistoryView()
                            .padding()
                    } else {
                        GroupedDrinksListView(drinks: groupedDrinks)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Drink History")
            .refreshable {
                await loadDrinks()
            }
            .onAppear {
                Task {
                    await loadDrinks()
                }
            }
        }
    }
    
    private var groupedDrinks: [Date: [Drink]] {
        let drinks = filteredDrinks
        
        // Group by date
        let calendar = Calendar.current
        var result: [Date: [Drink]] = [:]
        
        for drink in drinks {
            let date = calendar.startOfDay(for: drink.timestamp)
            if result[date] != nil {
                result[date]?.append(drink)
            } else {
                result[date] = [drink]
            }
        }
        
        // Sort drinks within each group
        for (date, drinks) in result {
            result[date] = drinks.sorted { $0.timestamp > $1.timestamp }
        }
        
        return result
    }
    
    private var filteredDrinks: [Drink] {
        let now = Date()
        
        switch selectedTimeframe {
        case .day:
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            return drinkViewModel.recentDrinks.filter { $0.timestamp > oneDayAgo }
        case .week:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return drinkViewModel.recentDrinks.filter { $0.timestamp > oneWeekAgo }
        case .month:
            let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return drinkViewModel.recentDrinks.filter { $0.timestamp > oneMonthAgo }
        }
    }
    
    private func loadDrinks() async {
        isLoading = true
        await drinkViewModel.loadRecentDrinks(userId: userViewModel.currentUser.id)
        isLoading = false
    }
}

struct StatsSummaryView: View {
    let timeframe: HistoryView.TimeFrame
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatCard(title: "Drinks", value: "5", icon: "wineglass")
                StatCard(title: "Standard", value: "7.2", icon: "scalemass")
                StatCard(title: "Days", value: "3", icon: "calendar")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct GroupedDrinksListView: View {
    let drinks: [Date: [Drink]]
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(drinks.keys.sorted(by: >), id: \.self) { date in
                if let drinksForDate = drinks[date] {
                    VStack(alignment: .leading, spacing: 8) {
                        // Date header
                        Text(formattedDate(date))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Drinks for this date
                        ForEach(drinksForDate) { drink in
                            DrinkRowView(drink: drink) {
                                Task {
                                    await drinkViewModel.deleteDrink(id: drink.id)
                                }
                            }
                            .padding(.horizontal)
                            
                            if drink != drinksForDate.last {
                                Divider()
                                    .padding(.leading, 60)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Daily summary
                        DailySummaryView(drinks: drinksForDate)
                            .padding(.top, 8)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct DailySummaryView: View {
    let drinks: [Drink]
    
    private var totalStandardDrinks: Double {
        drinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    private var drinkTypeDistribution: [DrinkType: Int] {
        var result: [DrinkType: Int] = [:]
        for drink in drinks {
            result[drink.type, default: 0] += 1
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text("\(drinks.count) drinks • \(totalStandardDrinks.formatted()) standard")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Distribution icons
                HStack(spacing: 4) {
                    ForEach(drinkTypeDistribution.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { type in
                        if let count = drinkTypeDistribution[type] {
                            Image(systemName: type.systemIconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No drink history found")
                .font(.headline)
            
            Text("Your drink history will appear here after you log drinks.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.top, 50)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environmentObject(UserViewModel())
            .environmentObject(DrinkViewModel())
    }
}
