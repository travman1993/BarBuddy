//
//  DrinkTrackerViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import SwiftUI
import Combine

class DrinkTrackerViewModel: ObservableObject {
    // MARK: - Core Drink Tracker
    private var drinkTracker: DrinkTracker
    
    // MARK: - Published Properties
    @Published var drinks: [Drink] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    
    // MARK: - Interaction State
    @Published var isAddingDrink: Bool = false
    @Published var showingSuggestions: Bool = false
    @Published var isDrinkingSession: Bool = false
    @Published var sessionStartTime: Date? = nil
    
    // MARK: - Drink Analytics
    @Published var totalDrinkCost: Double = 0.0
    @Published var estimatedCalories: Int = 0
    @Published var waterConsumption: Double = 0.0
    @Published var lastHydrationTime: Date? = nil
    
    // MARK: - Drinking Statistics
    @Published var totalStandardDrinksToday: Double = 0.0
    @Published var peakBACToday: Double = 0.0
    @Published var drinkingStreak: Int = 0
    @Published var soberDays: Int = 0
    
    // MARK: - Dependencies
    private let settingsManager = AppSettingsManager.shared
    private let notificationManager = NotificationManager.shared
    private let watchSessionManager = WatchSessionManager.shared
    private let suggestionManager = DrinkSuggestionManager.shared
    private let emergencyContactManager = EmergencyContactManager.shared
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(drinkTracker: DrinkTracker = DrinkTracker()) {
        self.drinkTracker = drinkTracker
        
        setupBindings()
        refreshFromDrinkTracker()
        calculateDailyStats()
        checkForDrinkingSession()
    }

    // MARK: - Drinking Session Management
    private func checkForDrinkingSession() {
        // Check if we have recent drinks to determine if a drinking session is active
        let calendar = Calendar.current
        let recentDrinks = drinks.filter {
            calendar.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 6
        }
        
        if !recentDrinks.isEmpty {
            // If there are drinks in the last 6 hours, consider it an active session
            isDrinkingSession = true
            
            // Find the earliest drink timestamp as session start time
            if let earliestDrink = recentDrinks.min(by: { $0.timestamp < $1.timestamp }) {
                sessionStartTime = earliestDrink.timestamp
            }
        } else {
            // No recent drinks, no active session
            isDrinkingSession = false
            sessionStartTime = nil
        }
    }

    // MARK: - Cost Tracking
    private func saveDrinkCost(_ cost: Double) {
        // Save the drink cost to UserDefaults
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: currentDate)
        
        // Get any existing costs for today
        var dailyCosts = UserDefaults.standard.dictionary(forKey: "drinkCosts") as? [String: Double] ?? [:]
        
        // Add this cost to today's total
        dailyCosts[dateKey] = (dailyCosts[dateKey] ?? 0.0) + cost
        
        // Save back to UserDefaults
        UserDefaults.standard.set(dailyCosts, forKey: "drinkCosts")
    }

    private func loadDrinkCosts() {
        // Load costs for today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = dateFormatter.string(from: Date())
        
        // Get costs dictionary
        let costs = UserDefaults.standard.dictionary(forKey: "drinkCosts") as? [String: Double] ?? [:]
        
        // Set total cost for today
        totalDrinkCost = costs[todayKey] ?? 0.0
    }

    // This fixes the "Initialization of immutable value 'today'" warning
    private func updateStreaks() {
        let calendar = Calendar.current
        let currentDate = Date()
        let today = calendar.startOfDay(for: currentDate)
        
        // Rest of your existing updateStreaks function...
        // Check if had drinks today
        let hadDrinksToday = !drinks.filter { calendar.isDateInToday($0.timestamp) }.isEmpty
        
        if hadDrinksToday {
            // Count consecutive drinking days
            var streakCount = 1
            var currentDay = today
            
            while true {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                
                let hadDrinksOnDay = !drinks.filter { calendar.isDate($0.timestamp, inSameDayAs: previousDay) }.isEmpty
                
                if hadDrinksOnDay {
                    streakCount += 1
                    currentDay = previousDay
                } else {
                    break
                }
            }
            
            drinkingStreak = streakCount
            soberDays = 0
        } else {
            // Count consecutive sober days
            var soberCount = 1
            var currentDay = today
            
            while true {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                
                let hadDrinksOnDay = !drinks.filter { calendar.isDate($0.timestamp, inSameDayAs: previousDay) }.isEmpty
                
                if !hadDrinksOnDay {
                    soberCount += 1
                    currentDay = previousDay
                } else {
                    break
                }
            }
            
            soberDays = soberCount
            drinkingStreak = 0
        }
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // Observe drink tracker changes
        drinkTracker.objectWillChange
            .sink { [weak self] _ in
                self?.refreshFromDrinkTracker()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe settings changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshFromDrinkTracker()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Refresh
    private func refreshFromDrinkTracker() {
        drinks = drinkTracker.drinks
        userProfile = drinkTracker.userProfile
        currentBAC = drinkTracker.currentBAC
        timeUntilSober = drinkTracker.timeUntilSober
        
        // Recalculate derived values
        calculateDailyStats()
        calculateCostAndCalories()
        checkForDrinkingSession()
        updateWatchIfNeeded()
    }
    
    // MARK: - Drink Logging Methods
    func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double, cost: Double? = nil) {
        // Log the drink
        drinkTracker.addDrink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
        
        // Update cost if tracking spending
        if let cost = cost, settingsManager.saveAlcoholSpending {
            totalDrinkCost += cost
            saveDrinkCost(cost)
        }
        
        // Manage drinking session
        manageDrinkingSession()
        
        // Show drink suggestions
        showingSuggestions = true
        
        // Schedule notifications
        scheduleNotificationsIfNeeded()
        
        // Sync with Apple Watch
        updateWatchIfNeeded()
    }
    
    func removeDrink(_ drink: Drink) {
        drinkTracker.removeDrink(drink)
    }
    
    // MARK: - Session Management
    private func manageDrinkingSession() {
        if !isDrinkingSession {
            isDrinkingSession = true
            sessionStartTime = Date()
            
            // Schedule drinking duration alerts
            if settingsManager.enableDrinkingDurationAlerts {
                notificationManager.scheduleDrinkingDurationAlert(startTime: sessionStartTime!)
            }
        }
    }
    
    // MARK: - Calculation Methods
    private func calculateDailyStats() {
        let calendar = Calendar.current
        _ = calendar.startOfDay(for: Date())
        
        // Calculate total standard drinks today
        let todaysDrinks = drinks.filter {
            calendar.isDate($0.timestamp, inSameDayAs: Date())
        }
        
        totalStandardDrinksToday = todaysDrinks.reduce(0) { $0 + $1.standardDrinks }
        
        // Calculate peak BAC
        if !todaysDrinks.isEmpty {
            let totalAlcoholToday = todaysDrinks.reduce(0) {
                $0 + ($1.size * ($1.alcoholPercentage / 100) * 0.789)
            }
            
            let weight = userProfile.weight * 453.592 // Convert lbs to grams
            let bodyWaterConstant = userProfile.gender == .male ? 0.68 : 0.55
            
            let estimatedPeakBAC = (totalAlcoholToday / (weight * bodyWaterConstant)) * 100
            peakBACToday = max(peakBACToday, estimatedPeakBAC, currentBAC)
        }
        
        // Update drinking streaks
        updateStreaks()
    }
    
    private func calculateCostAndCalories() {
        // Calculate drink calories
        estimatedCalories = drinks.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }.reduce(0) { total, drink in
            // Alcohol calories (7 calories per gram of alcohol)
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789
            let alcoholCalories = Int(alcoholGrams * 7)
            
            // Carb calories based on drink type
            var carbCalories = 0
            switch drink.type {
            case .beer: carbCalories = Int(drink.size * 13)
            case .wine: carbCalories = Int(drink.size * 4)
            case .cocktail: carbCalories = Int(drink.size * 12)
            case .shot: carbCalories = Int(drink.size * 2)
            case .other: carbCalories = Int(drink.size * 8)
            }
            
            return total + alcoholCalories + carbCalories
        }
        
        // Load saved drink costs
        loadDrinkCosts()
    }
    
    // MARK: - Notification and Sync Methods
    private func scheduleNotificationsIfNeeded() {
        // BAC alerts
        if settingsManager.enableBACAlerts {
            notificationManager.scheduleBACNotification(bac: currentBAC)
        }
        
        // Hydration reminders
        if settingsManager.enableHydrationReminders {
            notificationManager.scheduleHydrationReminder()
        }
        
        // Morning check-in for late-night drinking
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        if settingsManager.enableMorningCheckIns && (hour >= 21 || hour <= 2) {
            notificationManager.scheduleAfterPartyReminder()
        }
    }
    
    private func updateWatchIfNeeded() {
        if settingsManager.syncWithAppleWatch {
            watchSessionManager.sendBACDataToWatch(
                bac: currentBAC,
                timeUntilSober: timeUntilSober
            )
        }
    }
    
    // MARK: - Utility Methods
    func getFormattedTimeUntilSober() -> String {
        let hours = Int(timeUntilSober) / 3600
        let minutes = (Int(timeUntilSober) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    func getSafetyStatus() -> SafetyStatus {
        if currentBAC < 0.04 {
            return .safe
        } else if currentBAC < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }

    
    func getDrinkSuggestions() -> [DrinkSuggestionManager.DrinkSuggestion] {
        return suggestionManager.getSuggestions(
            for: currentBAC,
            currentDrinkCount: drinks.filter {
                Calendar.current.isDateInToday($0.timestamp)
            }.count
        )
    }
    
    func contactEmergencyHelp() {
        if let firstContact = emergencyContactManager.emergencyContacts.first {
            emergencyContactManager.callEmergencyContact(firstContact)
        } else {
            // Fallback if no emergency contacts
            if let url = URL(string: "tel://911") {
                UIApplication.shared.open(url)
            }
        }
    }
}

// Extension with Statistics Methods
extension DrinkTrackerViewModel {
    // Get drinking history data for charts and analysis
    func getDrinkingHistoryData(timeFrame: HistoryView.TimeFrame) -> [Date: [Drink]] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -timeFrame.days, to: endDate) else {
            return [:]
        }
        
        let filteredDrinks = drinks.filter {
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        
        // Group by day
        return Dictionary(grouping: filteredDrinks) { drink in
            let components = calendar.dateComponents([.year, .month, .day], from: drink.timestamp)
            return calendar.date(from: components) ?? Date()
        }
    }
    
    // Get standard drinks by day
    func getStandardDrinksByDay(timeFrame: HistoryView.TimeFrame) -> [(date: Date, standardDrinks: Double)] {
        let drinksByDay = getDrinkingHistoryData(timeFrame: timeFrame)
        
        // Calculate standard drinks for each day
        var standardDrinksByDay: [(date: Date, standardDrinks: Double)] = []
        
        for (date, dayDrinks) in drinksByDay {
            let totalStandardDrinks = dayDrinks.reduce(0) { $0 + $1.standardDrinks }
            standardDrinksByDay.append((date: date, standardDrinks: totalStandardDrinks))
        }
        
        // Sort by date
        return standardDrinksByDay.sorted { $0.date < $1.date }
    }
    
    // Get BAC by hour (estimated)
    func getBACByHour(for date: Date) -> [(hour: Int, bac: Double)] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Get drinks for this day
        let dayDrinks = drinks.filter {
            calendar.isDate($0.timestamp, inSameDayAs: date)
        }
        
        var hourlyBAC: [(hour: Int, bac: Double)] = []
        
        // Calculate hourly BAC
        for hour in 0..<24 {
            let hourDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
            
            // Get drinks before this hour
            let drinksBeforeHour = dayDrinks.filter {
                $0.timestamp <= hourDate
            }
            
            // Calculate BAC at this hour (simplified)
            var bacAtHour = 0.0
            
            for drink in drinksBeforeHour {
                let hoursSinceDrink = hourDate.timeIntervalSince(drink.timestamp) / 3600
                
                // Each standard drink adds about 0.02% BAC for a 160lb person
                // This decreases by about 0.015% per hour
                let initialBACIncrease = drink.standardDrinks * 0.02
                let bacDecreaseFromTime = min(hoursSinceDrink * 0.015, initialBACIncrease)
                
                let remainingBAC = max(0, initialBACIncrease - bacDecreaseFromTime)
                bacAtHour += remainingBAC
            }
            
            hourlyBAC.append((hour: hour, bac: bacAtHour))
        }
        
        return hourlyBAC
    }
    
    // Get drinks by type (for pie charts)
    func getDrinksByType(timeFrame: HistoryView.TimeFrame) -> [DrinkType: Int] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -timeFrame.days, to: endDate) else {
            return [:]
        }
        
        let filteredDrinks = drinks.filter {
            $0.timestamp >= startDate && $0.timestamp <= endDate
        }
        
        var drinksByType: [DrinkType: Int] = [:]
        
        for drink in filteredDrinks {
            drinksByType[drink.type, default: 0] += 1
        }
        
        return drinksByType
    }
}
