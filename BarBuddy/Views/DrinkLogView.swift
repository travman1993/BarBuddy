//
//  DrinkLogView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI
import Charts
import Combine
import UserNotifications

struct DrinkLogView: View {
    @EnvironmentObject private var drinkTracker: DrinkTracker
    @State private var selectedDrinkType: DrinkType = .beer
    @State private var customSize: Double = 12.0
    @State private var customAlcoholPercentage: Double = 5.0
    @State private var showingCustomDrinkView = false
    @State private var showingQuickAddConfirmation = false
    @State private var lastAddedDrink: DrinkType?
    @State private var showHistoryChart = true
    @State private var confirmationTimer: Timer?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        ScrollView {
            if horizontalSizeClass == .regular {
                // Fixed iPad layout
                VStack(spacing: 20) {
                    // Top row with status and recent drinks in a balanced layout
                    HStack(alignment: .top, spacing: 20) {
                        // Right column - Recently added drinks (scrollable)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recent Drinks")
                                .font(.title3)
                                .padding(.bottom, 4)

                            ForEach(drinkTracker.drinks, id: \.id) { drink in
                                RecentlyAddedDrinkRow(drink: drink) { drinkToRemove in
                                    drinkTracker.removeDrink(drinkToRemove)
                                }
                            }
                        }
                        .padding()
                        .frame(height: 230)
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Bottom row with quick add options that adapt to width
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quick Add")
                                .font(.title3)

                            Spacer()

                            Button(action: {
                                withAnimation {
                                    showHistoryChart.toggle()
                                }
                            }) {
                                Label(showHistoryChart ? "Hide Chart" : "Show Chart",
                                      systemImage: showHistoryChart ? "chart.bar.xaxis" : "chart.bar")
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }

                        // Toast-style confirmation
                        if showingQuickAddConfirmation, let drink = lastAddedDrink {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(drink.rawValue) added")
                                    .font(.footnote)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Drink history chart
                        if showHistoryChart {
                            DrinkHistoryChart(drinks: drinkTracker.drinks)
                                .frame(height: 160)
                                .padding(.vertical, 6)
                        }

                        // Tablet layout - 3 drink buttons per row
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(DrinkType.allCases, id: \.self) { drinkType in
                                EnhancedQuickAddButton(
                                    drinkType: drinkType,
                                    action: {
                                        addDefaultDrink(type: drinkType)
                                    }
                                )
                            }
                        }

                        // Custom Drink Button
                        Button(action: {
                            selectedDrinkType = .beer
                            customSize = selectedDrinkType.defaultSize
                            customAlcoholPercentage = selectedDrinkType.defaultAlcoholPercentage
                            showingCustomDrinkView = true
                        }) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14))
                                Text("Custom Drink")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            } else {
                // iPhone layout (more compact)
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quick Add")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    showHistoryChart.toggle()
                                }
                            }) {
                                Label(showHistoryChart ? "Hide Chart" : "Show Chart",
                                      systemImage: showHistoryChart ? "chart.bar.xaxis" : "chart.bar")
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        if showingQuickAddConfirmation, let drink = lastAddedDrink {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("\(drink.rawValue) added")
                                    .font(.footnote)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if showHistoryChart {
                            DrinkHistoryChart(drinks: drinkTracker.drinks)
                                .frame(height: 160)
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(DrinkType.allCases, id: \.self) { drinkType in
                                EnhancedQuickAddButton(
                                    drinkType: drinkType,
                                    action: {
                                        addDefaultDrink(type: drinkType)
                                    }
                                )
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Button(action: {
                        selectedDrinkType = .beer
                        customSize = selectedDrinkType.defaultSize
                        customAlcoholPercentage = selectedDrinkType.defaultAlcoholPercentage
                        showingCustomDrinkView = true
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                            Text("Custom Drink")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Recently Added Drinks with scrollable box
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recent Drinks")
                                .font(.headline)
                                .padding(.bottom, 4)

                            ForEach(drinkTracker.drinks, id: \.id) { drink in
                                RecentlyAddedDrinkRow(drink: drink) { drinkToRemove in
                                    drinkTracker.removeDrink(drinkToRemove)
                                }
                                .font(.caption)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 220)
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Log Drink")
        .background(Color("AppBackground"))
        .sheet(isPresented: $showingCustomDrinkView) {
            EnhancedCustomDrinkView(
                selectedDrinkType: $selectedDrinkType,
                size: $customSize,
                alcoholPercentage: $customAlcoholPercentage,
                onSave: {
                    addCustomDrink(
                        type: selectedDrinkType,
                        size: customSize,
                        alcoholPercentage: customAlcoholPercentage
                    )
                    showingCustomDrinkView = false
                }
            )
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
    }
    
    private func addCustomDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        drinkTracker.addDrink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
    }
    
    
    // Enhanced Quick Add Button
    struct EnhancedQuickAddButton: View {
        let drinkType: DrinkType
        let action: () -> Void
        
        var drinkTypeColor: Color {
            switch drinkType {
            case .beer:
                return Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
            case .wine:
                return Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
            case .cocktail:
                return Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
            case .shot:
                return Color(red: 0.5, green: 0.2, blue: 0.7) // Purple
            case .other:
                return Color(red: 0.4, green: 0.4, blue: 0.4) // Gray
            }
        }
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    Text(drinkType.icon)
                        .font(.title)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(drinkType.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(Int(drinkType.defaultSize))oz, \(Int(drinkType.defaultAlcoholPercentage))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(drinkTypeColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Enhanced Custom Drink View
    struct EnhancedCustomDrinkView: View {
        @Environment(\.presentationMode) var presentationMode
        @Binding var selectedDrinkType: DrinkType
        @Binding var size: Double
        @Binding var alcoholPercentage: Double
        let onSave: () -> Void
        
        var body: some View {
            NavigationView {
                VStack {
                    List {
                        Section(header: Text("Drink Type")) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(DrinkType.allCases, id: \.self) { type in
                                        DrinkTypeSelectionButton(
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
                                .padding(.vertical, 8)
                            }
                        }
                        
                        Section(header: Text("Size")) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(String(format: "%.1f", size)) oz")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Quick preset buttons
                                    HStack(spacing: 8) {
                                        SizePresetButton(size: 8.0, currentSize: $size)
                                        SizePresetButton(size: 12.0, currentSize: $size)
                                        SizePresetButton(size: 16.0, currentSize: $size)
                                    }
                                }
                                
                                Slider(value: $size, in: 1...32, step: 0.5)
                                    .accentColor(drinkTypeColor)
                                
                                SizeVisualization(size: size, drinkType: selectedDrinkType)
                                    .frame(height: 80)
                            }
                        }
                        
                        Section(header: Text("Alcohol Percentage")) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(String(format: "%.1f", alcoholPercentage))%")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Quick preset buttons
                                    HStack(spacing: 8) {
                                        PercentagePresetButton(percentage: 5.0, currentPercentage: $alcoholPercentage)
                                        PercentagePresetButton(percentage: 12.0, currentPercentage: $alcoholPercentage)
                                        PercentagePresetButton(percentage: 40.0, currentPercentage: $alcoholPercentage)
                                    }
                                }
                                
                                Slider(value: $alcoholPercentage, in: 0.5...70, step: 0.5)
                                    .accentColor(drinkTypeColor)
                            }
                        }
                        
                        Section(header: Text("Equivalent To")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Standard Drinks:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "%.1f", calculateStandardDrinks()))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                // Visual representation of standard drinks
                                HStack(spacing: 2) {
                                    ForEach(0..<min(Int(calculateStandardDrinks() * 2), 10), id: \.self) { _ in
                                        Image(systemName: "wineglass.fill")
                                            .foregroundColor(drinkTypeColor.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    
                    // Add drink button
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Drink")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(drinkTypeColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("Custom Drink")
                .navigationBarItems(
                    trailing: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        
        var drinkTypeColor: Color {
            switch selectedDrinkType {
            case .beer:
                return Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
            case .wine:
                return Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
            case .cocktail:
                return Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
            case .shot:
                return Color(red: 0.5, green: 0.2, blue: 0.7) // Purple
            case .other:
                return Color(red: 0.4, green: 0.4, blue: 0.4) // Gray
            }
        }
        
        private func calculateStandardDrinks() -> Double {
            // A standard drink is defined as 0.6 fl oz of pure alcohol
            let pureAlcohol = size * (alcoholPercentage / 100)
            return pureAlcohol / 0.6
        }
    }
    
    // Drink type selection button for custom drink view
    struct DrinkTypeSelectionButton: View {
        let drinkType: DrinkType
        let isSelected: Bool
        let action: () -> Void
        
        var drinkTypeColor: Color {
            switch drinkType {
            case .beer:
                return Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
            case .wine:
                return Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
            case .cocktail:
                return Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
            case .shot:
                return Color(red: 0.5, green: 0.2, blue: 0.7) // Purple
            case .other:
                return Color(red: 0.4, green: 0.4, blue: 0.4) // Gray
            }
        }
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Text(drinkType.icon)
                        .font(.system(size: 28))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(isSelected ? drinkTypeColor : Color.gray.opacity(0.1))
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? drinkTypeColor : Color.clear, lineWidth: 2)
                        )
                    
                    Text(drinkType.rawValue)
                        .font(.caption)
                        .foregroundColor(isSelected ? drinkTypeColor : .primary)
                }
                .frame(width: 70)
                .padding(.vertical, 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Size preset button
    struct SizePresetButton: View {
        let size: Double
        @Binding var currentSize: Double
        
        var body: some View {
            Button(action: {
                currentSize = size
            }) {
                Text("\(Int(size))")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentSize == size ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(currentSize == size ? .white : .primary)
                    .font(.caption)
            }
        }
    }
    
    // Percentage preset button
    struct PercentagePresetButton: View {
        let percentage: Double
        @Binding var currentPercentage: Double
        
        var body: some View {
            Button(action: {
                currentPercentage = percentage
            }) {
                Text("\(Int(percentage))%")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(currentPercentage == percentage ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(currentPercentage == percentage ? .white : .primary)
                    .font(.caption)
            }
        }
    }
    
    // Visual representation of drink size
    struct SizeVisualization: View {
        let size: Double
        let drinkType: DrinkType
        
        var body: some View {
            HStack(spacing: 20) {
                // Show a visual representation of the drink size
                ZStack(alignment: .bottom) {
                    // Container
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 80)
                    
                    // Liquid fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(drinkTypeColor.opacity(0.8))
                        .frame(width: 46, height: min(size / 20 * 80, 78))
                        .padding(.bottom, 1)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Size reference:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if drinkType == .beer {
                        Text("Standard can: 12 oz")
                            .font(.caption)
                    } else if drinkType == .wine {
                        Text("Standard pour: 5 oz")
                            .font(.caption)
                    } else if drinkType == .shot {
                        Text("Standard shot: 1.5 oz")
                            .font(.caption)
                    } else if drinkType == .cocktail {
                        Text("Standard cocktail: 4-6 oz")
                            .font(.caption)
                    }
                    
                    if size > 20 {
                        Text("⚠️ Large size")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        
        var drinkTypeColor: Color {
            switch drinkType {
            case .beer:
                return Color(red: 0.85, green: 0.65, blue: 0.13) // Amber
            case .wine:
                return Color(red: 0.7, green: 0.1, blue: 0.3) // Burgundy
            case .cocktail:
                return Color(red: 0.0, green: 0.6, blue: 0.8) // Blue
            case .shot:
                return Color(red: 0.5, green: 0.2, blue: 0.7) // Purple
            case .other:
                return Color(red: 0.4, green: 0.4, blue: 0.4) // Gray
            }
        }
    }
    
    // Drink History Chart
    struct DrinkHistoryChart: View {
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
                Chart {
                    ForEach(hourlyData) { hourData in
                        BarMark(
                            x: .value("Hour", hourData.hour),
                            y: .value("Drinks", hourData.standardDrinks)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Add horizontal rule for recommended maximum
                    RuleMark(y: .value("Max", 4))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Daily limit")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                VStack(alignment: .leading, spacing: 5) {
                    Text("Today's Drinks:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(hourlyData.indices, id: \.self) { index in
                            if index % 2 == 0 { // Only show every other hour to save space
                                let hourData = hourlyData[index]
                                VStack {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: max(hourData.standardDrinks * 20, 1))
                                    
                                    if index % 4 == 0 { // Only show every 4 hours
                                        Text("\(hourData.hour)")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
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
    
    struct RecentlyAddedDrinksView: View {
        let drinks: [Drink]
        let onRemove: (Drink) -> Void
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        
        var recentDrinks: [Drink] {
            // Get drinks from the last 24 hours
            return drinks.filter {
                Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
            }
            .sorted { $0.timestamp > $1.timestamp }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent Drinks")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                if recentDrinks.isEmpty {
                    Text("No drinks logged today")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // Use ScrollView for scrolling
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(recentDrinks) { drink in
                                RecentlyAddedDrinkRow(drink: drink) { drinkToRemove in
                                    onRemove(drinkToRemove)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    // Control height based on screen size
                    .frame(height: horizontalSizeClass == .regular ? 300 : 220)
                }
            }
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        
        func timeString(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    struct DrinkLogViewPreview: PreviewProvider {
        static var previews: some View {
            let drinkTracker = DrinkTracker()
            return NavigationView {
                DrinkLogView()
                    .environmentObject(drinkTracker)
            }
        }
    }
}
