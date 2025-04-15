//  DashboardView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var showingRideshareOptions = false
    @State private var showingEmergencyContact = false
    @State private var showingQuickAdd = false
    @State private var expandedSection: DashboardSection? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    enum DashboardSection {
        case drinkCount, drinks, safeTips
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    if horizontalSizeClass == .regular {
                        // iPad layout
                        // Top section with drink count indicator and quick actions
                        HStack(alignment: .top, spacing: 20) {
                            // Left column
                            VStack(spacing: 16) {
                                // Drink Count Indicator Section
                                DrinkCountStatusCard(
                                    drinkCount: drinkTracker.standardDrinkCount,
                                    drinkLimit: drinkTracker.drinkLimit,
                                    timeUntilReset: drinkTracker.timeUntilReset,
                                    isExpanded: true,
                                    onToggleExpand: {}
                                )
                                .environmentObject(drinkTracker)
                                
                                // Quick Actions in a grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    QuickActionButton(
                                        title: "Quick Add",
                                        systemImage: "plus.circle.fill",
                                        color: .blue
                                    ) {
                                        showingQuickAdd = true
                                    }
                                    
                                    QuickActionButton(
                                        title: "Get Ride",
                                        systemImage: "car.fill",
                                        color: .green
                                    ) {
                                        showingRideshareOptions = true
                                    }
                                    
                                    QuickActionButton(
                                        title: "Emergency",
                                        systemImage: "exclamationmark.triangle.fill",
                                        color: .red
                                    ) {
                                        showingEmergencyContact = true
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(width: geometry.size.width * 0.48)
                            
                            // Right column
                            VStack(spacing: 16) {
                                // Recent Drinks Summary (always expanded on iPad)
                                RecentDrinksSummary(
                                    drinks: drinkTracker.drinks,
                                    isExpanded: true,
                                    onToggleExpand: {}
                                )
                                
                                // Quick Share Button
                                if drinkTracker.standardDrinkCount > 0 {
                                    QuickShareButton(drinkCount: drinkTracker.standardDrinkCount, drinkLimit: drinkTracker.drinkLimit)
                                }
                            }
                            .frame(width: geometry.size.width * 0.48)
                        }
                        
                        // Bottom section with safety tips and drink suggestions
                        VStack(spacing: 16) {
                            // Safety Tips Section (always expanded on iPad)
                            SafetyTipsSection(
                                drinkCount: drinkTracker.standardDrinkCount,
                                drinkLimit: drinkTracker.drinkLimit,
                                isExpanded: true,
                                onToggleExpand: {}
                            )
                            
                            // Drink Suggestions (if drinks are present)
                            if drinkTracker.standardDrinkCount > 0 {
                                DrinkSuggestionView()
                            }
                        }
                    } else {
                        // iPhone layout (original layout)
                        VStack(spacing: 16) {
                            // Drink Count Indicator Section
                            DrinkCountStatusCard(
                                drinkCount: drinkTracker.standardDrinkCount,
                                drinkLimit: drinkTracker.drinkLimit,
                                timeUntilReset: drinkTracker.timeUntilReset,
                                isExpanded: expandedSection == .drinkCount,
                                onToggleExpand: {
                                    withAnimation {
                                        expandedSection = expandedSection == .drinkCount ? nil : .drinkCount
                                    }
                                }
                            )
                            .environmentObject(drinkTracker)
                            
                            // Quick Actions
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    title: "Quick Add",
                                    systemImage: "plus.circle.fill",
                                    color: .blue
                                ) {
                                    showingQuickAdd = true
                                }
                                
                                QuickActionButton(
                                    title: "Get Ride",
                                    systemImage: "car.fill",
                                    color: .green
                                ) {
                                    showingRideshareOptions = true
                                }
                                
                                QuickActionButton(
                                    title: "Emergency",
                                    systemImage: "exclamationmark.triangle.fill",
                                    color: .red
                                ) {
                                    showingEmergencyContact = true
                                }
                            }
                            .padding(.horizontal)
                            
                            // Recent Drinks Summary
                            RecentDrinksSummary(
                                drinks: drinkTracker.drinks,
                                isExpanded: expandedSection == .drinks,
                                onToggleExpand: {
                                    withAnimation {
                                        expandedSection = expandedSection == .drinks ? nil : .drinks
                                    }
                                }
                            )
                            
                            // Quick Share Button
                            if drinkTracker.standardDrinkCount > 0 {
                                QuickShareButton(drinkCount: drinkTracker.standardDrinkCount, drinkLimit: drinkTracker.drinkLimit)
                                    .padding(.horizontal)
                            }
                            
                            // Safety Tips Section
                            SafetyTipsSection(
                                drinkCount: drinkTracker.standardDrinkCount,
                                drinkLimit: drinkTracker.drinkLimit,
                                isExpanded: expandedSection == .safeTips,
                                onToggleExpand: {
                                    withAnimation {
                                        expandedSection = expandedSection == .safeTips ? nil : .safeTips
                                    }
                                }
                            )
                            
                            // Drink Suggestions (if drinks are present)
                            if drinkTracker.standardDrinkCount > 0 {
                                DrinkSuggestionView()
                            }
                        }
                    }
                }
                .padding(.vertical)
                .frame(width: geometry.size.width)
            }
        }
        .navigationTitle("Dashboard")
        .background(Color("AppBackground").edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddDrinkSheet()
        }
        .sheet(isPresented: $showingRideshareOptions) {
            RideshareOptionsView()
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

struct KeyInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let warning: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(warning ? .red : .blue)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(warning ? .red : .primary)
        }
    }
}

// MARK: - Drink Count Status Card
struct DrinkCountStatusCard: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    let drinkCount: Double
    let drinkLimit: Double
    let timeUntilReset: TimeInterval
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    @State private var showingLimitSetting = false
    
    var safetyStatus: SafetyStatus {
        if drinkCount >= drinkLimit {
            return .unsafe
        } else if drinkCount >= drinkLimit * 0.75 {
            return .borderline
        } else {
            return .safe
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
            // Main drink count display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT DRINKS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f", drinkCount))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                if timeUntilReset > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("RESETS IN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTimeUntilReset(timeUntilReset))
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
                
                if drinkCount >= drinkLimit {
                    Text("Limit Reached")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else {
                    Text("\(String(format: "%.1f", drinkLimit - drinkCount)) drinks remaining")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(statusColor)
            
            if isExpanded {
                VStack(spacing: 15) {
                    // Drink limit setting (editable)
                    Button(action: {
                        showingLimitSetting.toggle()
                    }) {
                        HStack {
                            Text("Drink Limit:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(String(format: "%.1f", drinkLimit)) standard drinks")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(showingLimitSetting ? 90 : 0))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if showingLimitSetting {
                        DrinkLimitSettingView(initialLimit: drinkLimit)
                            .padding(.top, -10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Drink progress bar
                    ProgressBar(value: min(drinkCount / drinkLimit, 1.0), color: statusColor)
                        .frame(height: 8)
                    
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
        .animation(.easeInOut, value: showingLimitSetting)
    }
    
    private func formatTimeUntilReset(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(value))
                    .cornerRadius(5)
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Recent Drinks Summary
struct RecentDrinksSummary: View {
    let drinks: [Drink]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
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
            HStack {
                Text("Recent Drinks")
                    .font(.headline)
                
                Spacer()
                
                Text("\(recentDrinks.count) drinks today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            
            if recentDrinks.isEmpty {
                Text("No drinks recorded in the last 24 hours")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appCardBackground)
            } else {
                // Summary row
                HStack(spacing: 0) {
                    Statistic(
                        title: "Total Drinks",
                        value: "\(recentDrinks.count)",
                        icon: "drop.fill"
                    )
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    Statistic(
                        title: "Standard Drinks",
                        value: String(format: "%.1f", totalStandardDrinks),
                        icon: "wineglass"
                    )
                    
                    if !isExpanded {
                        Divider()
                            .padding(.vertical, 10)
                        
                        Statistic(
                            title: "Last Drink",
                            value: recentDrinks.first != nil ? timeAgo(recentDrinks.first!.timestamp) : "-",
                            icon: "clock"
                        )
                    }
                }
                .padding(.vertical, 10)
                .background(Color.appCardBackground)
                
                if isExpanded {
                    // List of drinks with scroll view when needed
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(recentDrinks) { drink in
                                DrinkHistoryRow(drink: drink)
                                
                                if drink.id != recentDrinks.last?.id {
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
                    }
                    .frame(maxHeight: 300) // Set maximum height for scrolling
                    .background(Color.appCardBackground)
                }
            }
        }
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

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
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct Statistic: View {
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Share Button
struct QuickShareButton: View {
    let drinkCount: Double
    let drinkLimit: Double
    @State private var showingShareOptions = false
    
    var body: some View {
        Button(action: {
            showingShareOptions = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                Text("Share My Status")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingShareOptions) {
            ShareView()
        }
    }
}

// MARK: - Safety Tips Section
struct SafetyTipsSection: View {
    let drinkCount: Double
    let drinkLimit: Double
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Safety Tips")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onToggleExpand) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            
            // Quick tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .padding(.trailing, 5)
                
                Text(quickTip)
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.1))
            
            if isExpanded {
                // Extended tips
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(safetyTips, id: \.self) { tip in
                        TipRow(text: tip)
                    }
                }
                .padding()
                .background(Color.appCardBackground)
            }
        }
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    var quickTip: String {
        if drinkCount >= drinkLimit {
            return "You've reached your drink limit. Consider switching to water."
        } else if drinkCount >= drinkLimit * 0.75 {
            return "You're approaching your drink limit. Remember to stay hydrated."
        } else if drinkCount > 0 {
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
            "Remember that coffee doesn't sober you up - only time can help."
        ]
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Quick Add Drink Sheet
struct QuickAddDrinkSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var drinkTracker: DrinkTracker
    @State private var selectedDrinkType: DrinkType = .beer
    @State private var size: Double = 12.0
    @State private var alcoholPercentage: Double = 5.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Drink Type")) {
                    Picker("Type", selection: $selectedDrinkType) {
                        ForEach(DrinkType.allCases, id: \.self) { type in
                            HStack {
                                Text(type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .onChange(of: selectedDrinkType) { oldValue, newValue in
                        size = selectedDrinkType.defaultSize
                        alcoholPercentage = selectedDrinkType.defaultAlcoholPercentage
                    }
                }
                
                Section(header: Text("Size")) {
                    HStack {
                        Text("\(String(format: "%.1f", size)) oz")
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $size, in: 1...24, step: 0.5)
                    }
                }
                
                Section(header: Text("Alcohol Percentage")) {
                    HStack {
                        Text("\(String(format: "%.1f", alcoholPercentage))%")
                            .frame(width: 60, alignment: .leading)
                        
                        Slider(value: $alcoholPercentage, in: 0.5...70, step: 0.5)
                    }
                }
                
                Section(header: Text("Equivalent To")) {
                    HStack {
                        Text("Standard Drinks:")
                        Spacer()
                        Text(String(format: "%.1f", calculateStandardDrinks()))
                            .fontWeight(.bold)
                    }
                }
                
                Section {
                    Button(action: addDrink) {
                        Text("Add Drink")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                }
            }
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

// MARK: - Rideshare Options View
struct RideshareOptionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text("Get a Safe Ride Home")
                    .font(.headline)
                    .padding(.top, 5)
                
                if isProcessing {
                    ProgressView()
                        .padding()
                } else {
                    // Uber Button
                    Button(action: {
                        requestRide(service: "uber")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 18))
                            Text("Uber")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Lyft Button
                    Button(action: {
                        requestRide(service: "lyft")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 18))
                            Text("Lyft")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Cancel Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .padding(.vertical, 10)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
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

#Preview {
    DashboardView()
        .environmentObject(DrinkTracker())
}
