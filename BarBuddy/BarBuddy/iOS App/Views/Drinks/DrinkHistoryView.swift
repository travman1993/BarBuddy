import SwiftUI

struct DrinkHistoryView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var bacViewModel: BACViewModel
    
    @State private var timeFrame: TimeFrame = .week
    @State private var isLoading = false
    @State private var drinks: [Drink] = []
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.UI.standardPadding) {
                // Time frame selector
                Picker("Time Frame", selection: $timeFrame) {
                    ForEach(TimeFrame.allCases) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: timeFrame) { newValue in
                    loadDrinks()
                }
                
                // Stats summary
                DrinkStatsSummaryView(drinks: drinks, timeFrame: timeFrame)
                
                // Drink history list
                if isLoading {
                    ProgressView()
                        .padding()
                } else if drinks.isEmpty {
                    EmptyDrinksView {
                        // No action needed here, just informational
                    }
                } else {
                    // Group drinks by date
                    ForEach(groupedDrinkDates, id: \.self) { date in
                        DrinkDateSection(date: date, drinks: groupedDrinks[date] ?? [])
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Drink History")
        .onAppear {
            loadDrinks()
        }
        .refreshable {
            loadDrinks()
        }
    }
    
    private func loadDrinks() {
        isLoading = true
        
        Task {
            // Calculate the date range based on time frame
            let now = Date()
            let startDate: Date
            
            switch timeFrame {
            case .day:
                startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            case .week:
                startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            case .month:
                startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
            case .all:
                startDate = Date.distantPast
            }
            
            do {
                let loadedDrinks = try await drinkViewModel.getDrinksInRange(
                    userId: userViewModel.currentUser.id,
                    start: startDate,
                    end: now
                )
                
                await MainActor.run {
                    self.drinks = loadedDrinks
                    self.isLoading = false
                }
            } catch {
                print("Error loading drinks: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Grouped drinks by date
    private var groupedDrinks: [Date: [Drink]] {
        let calendar = Calendar.current
        var result: [Date: [Drink]] = [:]
        
        for drink in drinks {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
            if let date = calendar.date(from: dateComponents) {
                if result[date] != nil {
                    result[date]?.append(drink)
                } else {
                    result[date] = [drink]
                }
            }
        }
        
        // Sort drinks within each group by time (most recent first)
        for (date, drinksOnDate) in result {
            result[date] = drinksOnDate.sorted { $0.timestamp > $1.timestamp }
        }
        
        return result
    }
    
    // Dates sorted from most recent to oldest
    private var groupedDrinkDates: [Date] {
        groupedDrinks.keys.sorted(by: >)
    }
}

struct DrinkStatsSummaryView: View {
    let drinks: [Drink]
    let timeFrame: DrinkHistoryView.TimeFrame
    
    private var totalDrinks: Int {
        drinks.count
    }
    
    private var totalStandardDrinks: Double {
        drinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    private var averageDrinksPerDay: Double {
        let days: Double
        switch timeFrame {
        case .day: days = 1
        case .week: days = 7
        case .month: days = 30
        case .all:
            // Calculate actual number of days between first and last drink
            if let firstDrink = drinks.last, let lastDrink = drinks.first {
                let daysBetween = Calendar.current.dateComponents([.day], from: firstDrink.timestamp, to: lastDrink.timestamp).day ?? 1
                days = Double(max(1, daysBetween))
            } else {
                days = 1
            }
        }
        
        return totalDrinks / days
    }
    
    private var mostCommonType: DrinkType? {
        let typeCount = Dictionary(grouping: drinks, by: { $0.type })
            .mapValues { $0.count }
        
        return typeCount.max(by: { $0.value < $1.value })?.key
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatCard(title: "Drinks", value: "\(totalDrinks)", icon: "mug.fill")
                StatCard(title: "Standard", value: String(format: "%.1f", totalStandardDrinks), icon: "drop.fill")
                StatCard(title: "Daily Avg", value: String(format: "%.1f", averageDrinksPerDay), icon: "calendar")
            }
            
            if let mostCommon = mostCommonType {
                HStack {
                    Image(systemName: mostCommon.systemIconName)
                        .foregroundColor(.blue)
                    
                    Text("Most common drink: \(mostCommon.defaultName)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
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

struct DrinkDateSection: View {
    let date: Date
    let drinks: [Drink]
    
    private var dateString: String {
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
    
    private var totalStandardDrinks: Double {
        drinks.reduce(0) { $0 + $1.standardDrinks }
    }
    
    private var groupedByType: [DrinkType: Int] {
        Dictionary(grouping: drinks, by: { $0.type })
            .mapValues { $0.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date header
            Text(dateString)
                .font(.headline)
                .padding(.horizontal)
            
            // Drinks for this date
            VStack(spacing: 0) {
                ForEach(drinks) { drink in
                    NavigationLink(destination: DrinkDetailView(drink: drink)) {
                        DrinkRowView(drink: drink, onDelete: {
                            // This will be handled in the detail view
                        })
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if drink != drinks.last {
                        Divider()
                            .padding(.leading, 60)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.UI.cornerRadius)
            
            // Daily summary
            HStack {
                Text("\(drinks.count) drinks • \(totalStandardDrinks, specifier: "%.1f") standard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Display drink type distribution
                HStack(spacing: 4) {
                    ForEach(groupedByType.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { type in
                        if let count = groupedByType[type] {
                            Image(systemName: type.systemIconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
    }
}

struct EmptyDrinksView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mug.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No drinks in this time period")
                .font(.headline)
            
            Text("Your drink history will appear here when you log drinks.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct DrinkHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DrinkHistoryView()
                .environmentObject(UserViewModel())
                .environmentObject(DrinkViewModel())
                .environmentObject(BACViewModel())
        }
    }
}
