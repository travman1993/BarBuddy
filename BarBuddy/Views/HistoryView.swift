//
//  HistoryView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingStatsView = false
    @State private var showingDetailedAnalysis = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
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
        ScrollView {
            VStack(spacing: 16) {
                // Time frame selector
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Summary statistics
                DrinkingSummaryCard(drinks: filteredDrinks(), timeFrame: selectedTimeFrame)
                    .padding(.horizontal)
                
                // BAC Trend Chart
                BACTrendChart(drinks: filteredDrinks(), timeFrame: selectedTimeFrame)
                    .frame(height: 220)
                    .padding(.horizontal)
                
                // Buttons for analysis and stats
                HStack {
                    Button(action: { showingStatsView = true }) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                            Text("Drinking Stats")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: { showingDetailedAnalysis = true }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Analysis")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Drink history list
                Text("Drink History")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // DrinksHistoryList with adaptive height for tablet
                if horizontalSizeClass == .regular {
                    // Tablet layout - fixed height to fill available space
                    DrinksHistoryList(drinksByDate: drinksByDate)
                        .padding(.horizontal)
                        .frame(minHeight: 400) // Taller on tablet
                } else {
                    // Phone layout - scrollable
                    DrinksHistoryList(drinksByDate: drinksByDate)
                        .padding(.horizontal)
                }
                
                // Add a spacer only on phone to allow scrolling
                if horizontalSizeClass == .compact {
                    Spacer().frame(height: 20)
                }
            }
            .padding(.vertical)
            .background(Color("AppBackground"))
        }
        .navigationTitle("Drinking History")
        .sheet(isPresented: $showingStatsView) {
            DrinkingStatsView(drinks: filteredDrinks(), timeFrame: selectedTimeFrame)
        }
        .sheet(isPresented: $showingDetailedAnalysis) {
            DrinkingAnalysisView(drinks: filteredDrinks(), timeFrame: selectedTimeFrame)
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
    
    
    // Card showing drinking summary statistics
    struct DrinkingSummaryCard: View {
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
            // This is an approximation - would need proper calculation
            // Going with a simple calculation here for demonstration
            let calendar = Calendar.current
            var maxBAC = 0.0
            
            // Group drinks by hour to estimate BAC at each hour
            let drinksByHour = Dictionary(grouping: drinks) { drink in
                calendar.component(.hour, from: drink.timestamp) +
                calendar.component(.day, from: drink.timestamp) * 24
            }
            
            for (_, hourlyDrinks) in drinksByHour {
                let hourlyStandardDrinks = hourlyDrinks.reduce(0) { $0 + $1.standardDrinks }
                // Very rough estimation - multiply standard drinks by factor
                let estimatedBAC = hourlyStandardDrinks * 0.02
                maxBAC = max(maxBAC, estimatedBAC)
            }
            
            return maxBAC
        }
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Summary for Last \(timeFrame.rawValue)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 0) {
                    StatisticCard(
                        value: String(totalDrinks),
                        label: "Total\nDrinks",
                        systemImage: "drop.fill",
                        color: .blue
                    )
                    
                    StatisticCard(
                        value: String(format: "%.1f", totalStandardDrinks),
                        label: "Standard\nDrinks",
                        systemImage: "wineglass",
                        color: .purple
                    )
                    
                    StatisticCard(
                        value: String(format: "%.1f", averageDrinksPerDay),
                        label: "Daily\nAverage",
                        systemImage: "calendar",
                        color: .green
                    )
                    
                    StatisticCard(
                        value: String(format: "%.3f", maxBACReached),
                        label: "Max\nBAC",
                        systemImage: "gauge",
                        color: .red
                    )
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Individual statistic card
    struct StatisticCard: View {
        let value: String
        let label: String
        let systemImage: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
    
    // BAC Trend Chart showing estimated BAC over time
    struct BACTrendChart: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        var chartData: [BACPoint] {
            guard !drinks.isEmpty else { return [] }
            
            let calendar = Calendar.current
            
            // Get date range
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -timeFrame.days, to: endDate) ?? Date()
            
            var currentDate = startDate
            var points: [BACPoint] = []
            
            // Create a function to calculate BAC for a specific time
            func bacAtTime(_ date: Date) -> Double {
                // This is a simplified BAC calculation
                // In a real app, you'd use the Widmark formula or similar
                
                // Get drinks before this time
                let relevantDrinks = drinks.filter { $0.timestamp <= date }
                
                // Calculate BAC for each drink and account for time passed
                var totalBAC = 0.0
                for drink in relevantDrinks {
                    let hoursSinceDrink = date.timeIntervalSince(drink.timestamp) / 3600
                    
                    // Each standard drink adds about 0.02% BAC for a 160lb person
                    // This decreases by about 0.015% per hour
                    let initialBACIncrease = drink.standardDrinks * 0.02
                    let bacDecreaseFromTime = min(hoursSinceDrink * 0.015, initialBACIncrease)
                    
                    let remainingBAC = max(0, initialBACIncrease - bacDecreaseFromTime)
                    totalBAC += remainingBAC
                }
                
                return totalBAC
            }
            
            // Create data points (more for shorter timeframes, fewer for longer ones)
            let interval: TimeInterval
            switch timeFrame {
            case .day: interval = 3600 // hourly
            case .week: interval = 6 * 3600 // every 6 hours
            case .month: interval = 24 * 3600 // daily
            case .threeMonths: interval = 3 * 24 * 3600 // every 3 days
            case .year: interval = 7 * 24 * 3600 // weekly
            }
            
            while currentDate <= endDate {
                points.append(BACPoint(date: currentDate, bac: bacAtTime(currentDate)))
                currentDate = currentDate.addingTimeInterval(interval)
            }
            
            // Ensure we include the current time
            points.append(BACPoint(date: endDate, bac: bacAtTime(endDate)))
            
            return points
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("BAC Trend")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(chartData) { point in
                            LineMark(
                                x: .value("Time", point.date),
                                y: .value("BAC", point.bac)
                            )
                            .foregroundStyle(Color.red.gradient)
                            .interpolationMethod(.catmullRom)
                        }
                        
                        // Add a line for the legal driving limit
                        RuleMark(y: .value("Legal Limit", 0.08))
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .trailing) {
                                Text("Legal Limit")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                    }
                    .chartYScale(domain: 0...(maxBAC * 1.2))
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(formatDate(date))
                                        .font(.caption)
                                }
                            }
                        }
                    }
                } else {
                    // Fallback for iOS 15
                    HStack(alignment: .bottom, spacing: 4) {
                        // Create a simple view for older iOS versions
                        ForEach(Array(chartData.enumerated()), id: \.element.id) { index, point in
                            if index % max(1, chartData.count / 20) == 0 { // Show at most ~20 points
                                VStack {
                                    Rectangle()
                                        .fill(point.bac >= 0.08 ? Color.red : Color.orange)
                                        .frame(width: 4, height: max(point.bac * 1000, 1))
                                    
                                    if index % max(1, chartData.count / 10) == 0 { // Show fewer labels
                                        Text(formatDate(point.date))
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                            .rotationEffect(.degrees(-45))
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 180)
                }
                
                // Additional information
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peak BAC: \(String(format: "%.3f", maxBAC))")
                        .font(.caption)
                        .foregroundColor(maxBAC >= 0.08 ? .red : .primary)
                    
                    if maxBAC >= 0.08 {
                        Text("⚠️ Exceeded legal limit during this period")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
        
        var maxBAC: Double {
            chartData.map { $0.bac }.max() ?? 0.0
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            
            switch timeFrame {
            case .day:
                formatter.dateFormat = "h a"
            case .week:
                formatter.dateFormat = "EEE"
            case .month, .threeMonths:
                formatter.dateFormat = "MMM d"
            case .year:
                formatter.dateFormat = "MMM"
            }
            
            return formatter.string(from: date)
        }
        
        struct BACPoint: Identifiable {
            let id = UUID()
            let date: Date
            let bac: Double
        }
    }
    
    // Drinks history list grouped by date
    struct DrinksHistoryList: View {
        let drinksByDate: [Date: [Drink]]
        
        var body: some View {
            VStack(spacing: 16) {
                ForEach(drinksByDate.keys.sorted(by: >), id: \.self) { date in
                    DayDrinksCard(date: date, drinks: drinksByDate[date] ?? [])
                }
            }
        }
    }
    
    // Card showing drinks for a specific day
    struct DayDrinksCard: View {
        let date: Date
        let drinks: [Drink]
        @State private var expanded = false
        
        var totalStandardDrinks: Double {
            drinks.reduce(0) { $0 + $1.standardDrinks }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Date header with expand/collapse button
                Button(action: {
                    withAnimation {
                        expanded.toggle()
                    }
                }) {
                    HStack {
                        Text(formatDate(date))
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(drinks.count) drinks • \(String(format: "%.1f", totalStandardDrinks)) std")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(expanded ? 12 : 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded view with drink details
                if expanded {
                    VStack(spacing: 0) {
                        Divider()
                        
                        ForEach(drinks.sorted(by: { $0.timestamp > $1.timestamp })) { drink in
                            DrinkHistoryRow(drink: drink)
                            
                            if drink.id != drinks.sorted(by: { $0.timestamp > $1.timestamp }).last?.id {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                }
            }
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
        
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
    
    // Row for an individual drink
    struct DrinkHistoryRow: View {
        let drink: Drink
        
        var body: some View {
            HStack {
                Text(drink.type.icon)
                    .font(.title2)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(drink.type.rawValue)
                        .fontWeight(.medium)
                    
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
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // Detailed statistics view
    struct DrinkingStatsView: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        @Environment(\.presentationMode) var presentationMode
        
        var drinksByType: [DrinkType: Int] {
            var counts: [DrinkType: Int] = [:]
            for drink in drinks {
                counts[drink.type, default: 0] += 1
            }
            return counts
        }
        
        var totalStandardDrinks: Double {
            drinks.reduce(0) { $0 + $1.standardDrinks }
        }
        
        var standardDrinksByType: [DrinkType: Double] {
            var counts: [DrinkType: Double] = [:]
            for drink in drinks {
                counts[drink.type, default: 0] += drink.standardDrinks
            }
            return counts
        }
        
        var drinksByDay: [Int: Int] {
            var counts: [Int: Int] = [:]
            let calendar = Calendar.current
            for drink in drinks {
                let weekday = calendar.component(.weekday, from: drink.timestamp)
                counts[weekday, default: 0] += 1
            }
            return counts
        }
        
        var drinksByHour: [Int: Int] {
            var counts: [Int: Int] = [:]
            let calendar = Calendar.current
            for drink in drinks {
                let hour = calendar.component(.hour, from: drink.timestamp)
                counts[hour, default: 0] += 1
            }
            return counts
        }
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Drinks by type
                        StatsSectionCard(title: "Drinks by Type") {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(DrinkType.allCases, id: \.self) { type in
                                        BarMark(
                                            x: .value("Type", type.rawValue),
                                            y: .value("Count", drinksByType[type] ?? 0)
                                        )
                                        .foregroundStyle(by: .value("Type", type.rawValue))
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                // Fallback for iOS 15
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(DrinkType.allCases, id: \.self) { type in
                                        VStack {
                                            Text("\(drinksByType[type] ?? 0)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Rectangle()
                                                .fill(typeColor(type))
                                                .frame(width: 30, height: CGFloat((drinksByType[type] ?? 0) * 10 + 1))
                                            
                                            Text(type.icon)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                        
                        // Standard drinks by type
                        StatsSectionCard(title: "Standard Drinks by Type") {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(DrinkType.allCases, id: \.self) { type in
                                        if let count = standardDrinksByType[type], count > 0 {
                                            SectorMark(
                                                angle: .value("Standard Drinks", count),
                                                innerRadius: .ratio(0.5),
                                                angularInset: 1.5
                                            )
                                            .foregroundStyle(by: .value("Type", type.rawValue))
                                        }
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                // Fallback for iOS 15
                                HStack(alignment: .center, spacing: 12) {
                                    ForEach(DrinkType.allCases, id: \.self) { type in
                                        if let count = standardDrinksByType[type], count > 0 {
                                            VStack {
                                                Text(type.icon)
                                                    .font(.title3)
                                                
                                                Text(String(format: "%.1f", count))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 50)
                                        }
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                        
                        // Drinks by day of week
                        StatsSectionCard(title: "Drinks by Day of Week") {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(1...7, id: \.self) { day in
                                        BarMark(
                                            x: .value("Day", dayName(day)),
                                            y: .value("Count", drinksByDay[day] ?? 0)
                                        )
                                        .foregroundStyle(Color.blue.gradient)
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                // Fallback for iOS 15
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(1...7, id: \.self) { day in
                                        VStack {
                                            Text("\(drinksByDay[day] ?? 0)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Rectangle()
                                                .fill(Color.blue)
                                                .frame(width: 20, height: CGFloat((drinksByDay[day] ?? 0) * 10 + 1))
                                            
                                            Text(dayName(day).prefix(1))
                                                .font(.caption)
                                        }
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                        
                        // Drinks by hour
                        StatsSectionCard(title: "Drinks by Hour") {
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(0..<24, id: \.self) { hour in
                                        BarMark(
                                            x: .value("Hour", "\(hour):00"),
                                            y: .value("Count", drinksByHour[hour] ?? 0)
                                        )
                                        .foregroundStyle(Color.purple.gradient)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: 4)) { value in
                                        AxisGridLine()
                                        AxisValueLabel {
                                            if let hour = value.as(String.self) {
                                                Text(hour)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                // Fallback for iOS 15
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        ForEach(0..<24, id: \.self) { hour in
                                            VStack {
                                                Text("\(drinksByHour[hour] ?? 0)")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                                
                                                Rectangle()
                                                    .fill(Color.purple)
                                                    .frame(width: 12, height: CGFloat((drinksByHour[hour] ?? 0) * 10 + 1))
                                                
                                                if hour % 4 == 0 {
                                                    Text("\(hour)")
                                                        .font(.system(size: 8))
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 150)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Key statistics
                        StatsSectionCard(title: "Key Statistics") {
                            VStack(alignment: .leading, spacing: 12) {
                                KeyStatRow(label: "Total Drinks", value: "\(drinks.count)")
                                KeyStatRow(label: "Total Standard Drinks", value: String(format: "%.1f", totalStandardDrinks))
                                KeyStatRow(label: "Average per Day", value: String(format: "%.1f", Double(drinks.count) / Double(timeFrame.days)))
                                KeyStatRow(label: "Most Common Type", value: mostCommonDrinkType)
                                KeyStatRow(label: "Most Active Day", value: mostActiveDayOfWeek)
                                KeyStatRow(label: "Most Active Hour", value: mostActiveHour)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Drinking Statistics")
                .navigationBarItems(trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        
        var mostCommonDrinkType: String {
            guard let maxType = drinksByType.max(by: { $0.value < $1.value }) else {
                return "None"
            }
            return "\(maxType.key.icon) \(maxType.key.rawValue)"
        }
        
        var mostActiveDayOfWeek: String {
            guard let maxDay = drinksByDay.max(by: { $0.value < $1.value }) else {
                return "None"
            }
            return dayName(maxDay.key)
        }
        
        var mostActiveHour: String {
            guard let maxHour = drinksByHour.max(by: { $0.value < $1.value }) else {
                return "None"
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            
            let calendar = Calendar.current
            var components = DateComponents()
            components.hour = maxHour.key
            let date = calendar.date(from: components) ?? Date()
            
            return formatter.string(from: date)
        }
        
        func dayName(_ day: Int) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            let calendar = Calendar.current
            
            var components = DateComponents()
            components.weekday = day
            let date = calendar.date(from: components) ?? Date()
            
            return formatter.string(from: date)
        }
        
        func typeColor(_ type: DrinkType) -> Color {
            switch type {
            case .beer: return .yellow
            case .wine: return .red
            case .cocktail: return .blue
            case .shot: return .purple
            case .other: return .gray
            }
        }
    }
    
    // Section card for statistics view
    struct StatsSectionCard<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                content
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Key statistic row
    struct KeyStatRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
    
    // Drinking analysis view
    struct DrinkingAnalysisView: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // BAC analysis
                        BACAnalysisCard(drinks: drinks, timeFrame: timeFrame)
                        
                        // Drinking patterns
                        DrinkingPatternsCard(drinks: drinks, timeFrame: timeFrame)
                        
                        // Cost analysis (estimated)
                        DrinkingCostCard(drinks: drinks, timeFrame: timeFrame)
                        
                        // Health impacts
                        HealthImpactCard(drinks: drinks, timeFrame: timeFrame)
                        
                        // Recommendations
                        RecommendationsCard(drinks: drinks, timeFrame: timeFrame)
                    }
                    .padding()
                }
                .navigationTitle("Drinking Analysis")
                .navigationBarItems(trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    // BAC Analysis Card
    struct BACAnalysisCard: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        var exceededLegalLimitCount: Int {
            // This is a simplified approximation
            let dailyDrinks = groupDrinksByDay()
            
            var count = 0
            for (_, dailyDrinkList) in dailyDrinks {
                let totalStandardDrinks = dailyDrinkList.reduce(0) { $0 + $1.standardDrinks }
                // Very roughly, 4 standard drinks in a day might put someone over 0.08 BAC
                if totalStandardDrinks >= 4.0 {
                    count += 1
                }
            }
            
            return count
        }
        
        var maxStandardDrinksInDay: Double {
            let dailyDrinks = groupDrinksByDay()
            
            var maxDrinks = 0.0
            for (_, dailyDrinkList) in dailyDrinks {
                let totalStandardDrinks = dailyDrinkList.reduce(0) { $0 + $1.standardDrinks }
                maxDrinks = max(maxDrinks, totalStandardDrinks)
            }
            
            return maxDrinks
        }
        
        private func groupDrinksByDay() -> [Date: [Drink]] {
            let calendar = Calendar.current
            
            return Dictionary(grouping: drinks) { drink in
                let components = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
                return calendar.date(from: components) ?? Date()
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("BAC Analysis")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Days potentially over legal limit:")
                            .font(.subheadline)
                        
                        Text("\(exceededLegalLimitCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(exceededLegalLimitCount > 0 ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Maximum standard drinks in a day:")
                            .font(.subheadline)
                        
                        Text(String(format: "%.1f", maxStandardDrinksInDay))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(maxStandardDrinksInDay > 4 ? .red : .primary)
                    }
                }
                
                if exceededLegalLimitCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        Text("You may have exceeded the legal BAC limit on \(exceededLegalLimitCount) day\(exceededLegalLimitCount == 1 ? "" : "s") during this period.")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Drinking Patterns Card
    struct DrinkingPatternsCard: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        var daysBetweenDrinks: [Int] {
            let calendar = Calendar.current
            let sortedDates = drinks.map { $0.timestamp }.sorted()
            
            guard sortedDates.count > 1 else { return [] }
            
            var daysBetween: [Int] = []
            for i in 0..<sortedDates.count-1 {
                let components = calendar.dateComponents([.day], from: sortedDates[i], to: sortedDates[i+1])
                if let days = components.day, days > 0 {
                    daysBetween.append(days)
                }
            }
            
            return daysBetween
        }
        
        var averageDaysBetweenDrinking: Double {
            guard !daysBetweenDrinks.isEmpty else { return 0 }
            let sum = daysBetweenDrinks.reduce(0, +)
            return Double(sum) / Double(daysBetweenDrinks.count)
        }
        
        var longestBreak: Int {
            return daysBetweenDrinks.max() ?? 0
        }
        
        var daysWithDrinks: Int {
            let dailyDrinks = groupDrinksByDay()
            return dailyDrinks.count
        }
        
        var daysAnalyzed: Int {
            return timeFrame.days
        }
        
        var drinkingFrequency: Double {
            return Double(daysWithDrinks) / Double(daysAnalyzed)
        }
        
        private func groupDrinksByDay() -> [Date: [Drink]] {
            let calendar = Calendar.current
            
            return Dictionary(grouping: drinks) { drink in
                let components = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
                return calendar.date(from: components) ?? Date()
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Drinking Patterns")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Days with drinks:")
                            .font(.subheadline)
                        
                        Text("\(daysWithDrinks) of \(daysAnalyzed)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Drinking frequency:")
                            .font(.subheadline)
                        
                        Text(String(format: "%.0f%%", drinkingFrequency * 100))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(drinkingFrequency > 0.5 ? .orange : .primary)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg. days between:")
                            .font(.subheadline)
                        
                        Text(String(format: "%.1f", averageDaysBetweenDrinking))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Longest break:")
                            .font(.subheadline)
                        
                        Text("\(longestBreak) days")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                PatternAnalysisView(drinkingFrequency: drinkingFrequency)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    struct PatternAnalysisView: View {
        let drinkingFrequency: Double
        
        var patternDescription: String {
            if drinkingFrequency >= 0.85 {
                return "Daily drinker: You drink almost every day"
            } else if drinkingFrequency >= 0.5 {
                return "Regular drinker: You drink on most days"
            } else if drinkingFrequency >= 0.25 {
                return "Moderate drinker: You drink a few times per week"
            } else if drinkingFrequency >= 0.1 {
                return "Occasional drinker: You drink a few times per month"
            } else {
                return "Rare drinker: You drink very occasionally"
            }
        }
        
        var body: some View {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text(patternDescription)
                    .font(.footnote)
                    .italic()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // Drinking Cost Card (estimated)
    struct DrinkingCostCard: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        // Estimated costs per drink type
        let averageCosts: [DrinkType: Double] = [
            .beer: 5.00,
            .wine: 8.00,
            .cocktail: 12.00,
            .shot: 7.00,
            .other: 8.00
        ]
        
        var totalEstimatedCost: Double {
            var total = 0.0
            for drink in drinks {
                total += averageCosts[drink.type, default: 8.00]
            }
            return total
        }
        
        var averageWeeklyCost: Double {
            let weeks = Double(timeFrame.days) / 7.0
            guard weeks > 0 else { return 0 }
            return totalEstimatedCost / weeks
        }
        
        var annualProjectedCost: Double {
            return averageWeeklyCost * 52
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Estimated Cost")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total spent:")
                            .font(.subheadline)
                        
                        Text("$\(String(format: "%.2f", totalEstimatedCost))")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Weekly average:")
                            .font(.subheadline)
                        
                        Text("$\(String(format: "%.2f", averageWeeklyCost))")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected annual spending:")
                        .font(.subheadline)
                    
                    Text("$\(String(format: "%.2f", annualProjectedCost))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(annualProjectedCost > 1000 ? .orange : .primary)
                }
                
                if annualProjectedCost > 1000 {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("At this rate, you'll spend over $\(String(format: "%.0f", annualProjectedCost)) on drinks this year.")
                            .font(.footnote)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Health Impact Card
    struct HealthImpactCard: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        var weeklyStandardDrinks: Double {
            let totalStandardDrinks = drinks.reduce(0.0) { $0 + $1.standardDrinks }
            let weeks = Double(timeFrame.days) / 7.0
            guard weeks > 0 else { return 0 }
            return totalStandardDrinks / weeks
        }
        
        var healthRiskLevel: HealthRisk {
            if weeklyStandardDrinks > 14 {
                return .high
            } else if weeklyStandardDrinks > 7 {
                return .moderate
            } else {
                return .low
            }
        }
        
        enum HealthRisk {
            case low, moderate, high
            
            var color: Color {
                switch self {
                case .low: return .green
                case .moderate: return .yellow
                case .high: return .red
                }
            }
            
            var description: String {
                switch self {
                case .low: return "Low risk: Your drinking is within recommended guidelines."
                case .moderate: return "Moderate risk: Your drinking exceeds some health guidelines."
                case .high: return "High risk: Your drinking significantly exceeds health guidelines."
                }
            }
            
            var icon: String {
                switch self {
                case .low: return "checkmark.circle.fill"
                case .moderate: return "exclamationmark.triangle.fill"
                case .high: return "xmark.octagon.fill"
                }
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Health Impact")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly standard drinks:")
                        .font(.subheadline)
                    
                    Text(String(format: "%.1f", weeklyStandardDrinks))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(healthRiskLevel.color)
                }
                
                HStack {
                    Image(systemName: healthRiskLevel.icon)
                        .foregroundColor(healthRiskLevel.color)
                    
                    Text(healthRiskLevel.description)
                        .font(.footnote)
                }
                .padding()
                .background(healthRiskLevel.color.opacity(0.1))
                .cornerRadius(8)
                
                Text("Health guidelines recommend no more than 14 standard drinks per week and no more than 4 standard drinks on any single day.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Recommendations Card
    struct RecommendationsCard: View {
        let drinks: [Drink]
        let timeFrame: HistoryView.TimeFrame
        
        var weeklyStandardDrinks: Double {
            let totalStandardDrinks = drinks.reduce(0.0) { $0 + $1.standardDrinks }
            let weeks = Double(timeFrame.days) / 7.0
            guard weeks > 0 else { return 0 }
            return totalStandardDrinks / weeks
        }
        
        var recommendations: [String] {
            var results: [String] = []
            
            // Analyze frequency
            let calendar = Calendar.current
            let dailyDrinks = Dictionary(grouping: drinks) { drink in
                let components = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
                return calendar.date(from: components) ?? Date()
            }
            
            let daysWithDrinks = dailyDrinks.count
            let daysAnalyzed = timeFrame.days
            let drinkingFrequency = Double(daysWithDrinks) / Double(daysAnalyzed)
            
            // Check for high weekly consumption
            if weeklyStandardDrinks > 14 {
                results.append("Consider reducing your overall consumption to stay within health guidelines of 14 standard drinks per week.")
            }
            
            // Check for daily/near-daily drinking
            if drinkingFrequency > 0.7 {
                results.append("Consider adding more drink-free days to your week to avoid developing alcohol dependence.")
            }
            
            // Check for heavy single-day drinking
            var heavySingleDayCount = 0
            for (_, dailyDrinkList) in dailyDrinks {
                let totalStandardDrinks = dailyDrinkList.reduce(0) { $0 + $1.standardDrinks }
                if totalStandardDrinks > 4.0 {
                    heavySingleDayCount += 1
                }
            }
            
            if heavySingleDayCount > 0 {
                results.append("Try to limit your drinking to no more than 4 standard drinks on any single day to reduce health risks.")
            }
            
            // If no specific recommendations, add a general one
            if results.isEmpty {
                results.append("Your current drinking patterns appear to be within recommended guidelines. Continue to drink responsibly.")
            }
            
            return results
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Recommendations")
                    .font(.headline)
                
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .padding(.top, 2)
                        
                        Text(recommendation)
                            .font(.subheadline)
                    }
                }
                
                Divider()
                
                Text("Remember: These recommendations are based on general health guidelines and your specific drinking patterns. They are not medical advice.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
}
