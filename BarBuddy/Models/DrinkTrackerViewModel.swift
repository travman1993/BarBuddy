//
//  DrinkTrackerViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import Combine
import SwiftUI

class DrinkTrackerViewModel: ObservableObject {
    // Core drink tracker instance
    private var drinkTracker: DrinkTracker
    
    // Published properties that mirror the DrinkTracker properties
    @Published var drinks: [Drink] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    
    // Additional state properties
    @Published var isAddingDrink: Bool = false
    @Published var showingSuggestions: Bool = false
    @Published var isDrinkingSession: Bool = false
    @Published var sessionStartTime: Date? = nil
    @Published var totalDrinkCost: Double = 0.0
    @Published var estimatedCalories: Int = 0
    
    // Hydration tracking
    @Published var waterConsumption: Double = 0.0 // in fluid ounces
    @Published var lastHydrationTime: Date? = nil
    
    // Drinking stats
    @Published var totalStandardDrinksToday: Double = 0.0
    @Published var peakBACToday: Double = 0.0
    @Published var drinkingStreak: Int = 0
    @Published var soberDays: Int = 0
    
    // Dependencies
    private let notificationManager = NotificationManager.shared
    private let watchSessionManager = WatchSessionManager.shared
    private let settingsManager = AppSettingsManager.shared
    private let suggestionManager = DrinkSuggestionManager.shared
    private let emergencyContactManager = EmergencyContactManager.shared
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(drinkTracker: DrinkTracker = DrinkTracker()) {
        self.drinkTracker = drinkTracker
        
        // Set up bindings and initial state
        setupBindings()
        refreshFromDrinkTracker()
        calculateDailyStats()
        checkForDrinkingSession()
    }
    
    private func setupBindings() {
        // Observe the DrinkTracker properties
        drinkTracker.objectWillChange
            .sink { [weak self] _ in
                self?.refreshFromDrinkTracker()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe settings changes that might affect calculations
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshFromDrinkTracker()
            }
            .store(in: &cancellables)
    }
    
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
    
    // MARK: - Public Methods
    
    func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double, cost: Double? = nil) {
        drinkTracker.addDrink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage
        )
        
        // Update the total cost if tracking spending
        if let cost = cost, settingsManager.saveAlcoholSpending {
            totalDrinkCost += cost
            saveDrinkCost(cost)
        }
        
        // Update drinking session status
        if !isDrinkingSession {
            isDrinkingSession = true
            sessionStartTime = Date()
            
            // Schedule drinking duration alerts if enabled
            if settingsManager.enableDrinkingDurationAlerts {
                notificationManager.scheduleDrinkingDurationAlert(startTime: sessionStartTime!)
            }
        }
        
        // Check if we should show suggestions
        showingSuggestions = true
        
        // Schedule appropriate notifications
        scheduleNotificationsIfNeeded()
        
        // Sync with Apple Watch
        updateWatchIfNeeded()
    }
    
    func removeDrink(_ drink: Drink) {
        drinkTracker.removeDrink(drink)
        
        // Update watch and recalculate stats (handled by refreshFromDrinkTracker via binding)
    }
    
    func addWater(ounces: Double) {
        waterConsumption += ounces
        lastHydrationTime = Date()
        
        // Save hydration data
        saveHydrationData()
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        drinkTracker.updateUserProfile(profile)
        
        // Update the user profile in the settings manager as well
        settingsManager.weight = profile.weight
        settingsManager.gender = profile.gender
        settingsManager.saveSettings()
    }
    
    func resetDrinkingSession() {
        isDrinkingSession = false
        sessionStartTime = nil
        
        // Cancel any drinking duration notifications
        notificationManager.cancelNotificationsWithPrefix("duration-")
    }
    
    func checkSobriety() -> Bool {
        return currentBAC < 0.01
    }
    
    // MARK: - Helper Methods
    
    private func calculateDailyStats() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        // Calculate total standard drinks today
        let todaysDrinks = drinks.filter {
            calendar.isDate($0.timestamp, inSameDayAs: Date())
        }
        
        totalStandardDrinksToday = todaysDrinks.reduce(0) { $0 + $1.standardDrinks }
        
        // Calculate peak BAC (simplified estimate)
        if !todaysDrinks.isEmpty {
            // This is a very simplified approach - a real app would use a more sophisticated algorithm
            let totalAlcoholToday = todaysDrinks.reduce(0) {
                $0 + ($1.size * ($1.alcoholPercentage / 100) * 0.789)
            }
            
            // Simple estimation for peak BAC
            let weight = userProfile.weight * 453.592 // Convert lbs to grams
            let bodyWaterConstant = userProfile.gender == .male ? 0.68 : 0.55
            
            let estimatedPeakBAC = (totalAlcoholToday / (weight * bodyWaterConstant)) * 100
            peakBACToday = max(peakBACToday, estimatedPeakBAC, currentBAC)
        }
        
        // Update drinking streak and sober days
        updateStreaks()
    }
    
    private func calculateCostAndCalories() {
        // Calculate drink calories (rough estimate)
        estimatedCalories = drinks.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }.reduce(0) { total, drink in
            // Rough calorie estimation: 7 calories per gram of alcohol, plus carbs
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789
            let alcoholCalories = Int(alcoholGrams * 7)
            
            // Add estimated carb calories based on drink type
            var carbCalories = 0
            switch drink.type {
            case .beer:
                carbCalories = Int(drink.size * 13) // ~13 calories per oz from carbs in beer
            case .wine:
                carbCalories = Int(drink.size * 4)  // ~4 calories per oz from carbs in wine
            case .cocktail:
                carbCalories = Int(drink.size * 12) // Varies widely based on mixers
            case .shot:
                carbCalories = Int(drink.size * 2)  // Minimal carbs in spirits
            case .other:
                carbCalories = Int(drink.size * 8)  // Generic estimate
            }
            
            return total + alcoholCalories + carbCalories
        }
        
        // Load saved cost data
        loadDrinkCosts()
    }
    
    private func updateStreaks() {
        // Get drinking days in the last 30 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if had drinks today
        let hadDrinksToday = !drinks.filter { calendar.isDateInToday($0.timestamp) }.isEmpty
        
        // Check for consecutive drinking days
        if hadDrinksToday {
            // Count backwards to find the streak
            var streakCount = 1
            var currentDay = today
            
            while true {
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                
                // Check if had drinks on that day
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
            // Count sober days
            var soberCount = 1 // Today
            var currentDay = today
            
            while true {
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
                
                // Check if had drinks on that day
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
    
    private func checkForDrinkingSession() {
        let recentDrinks = drinks.filter {
            $0.timestamp.timeIntervalSinceNow > -6 * 3600 // Last 6 hours
        }
        
        if !recentDrinks.isEmpty && !isDrinkingSession {
            isDrinkingSession = true
            sessionStartTime = recentDrinks.min { $0.timestamp < $1.timestamp }?.timestamp
            
            // Schedule drinking duration alerts if enabled
            if let startTime = sessionStartTime, settingsManager.enableDrinkingDurationAlerts {
                notificationManager.scheduleDrinkingDurationAlert(startTime: startTime)
            }
        } else if recentDrinks.isEmpty && isDrinkingSession {
            resetDrinkingSession()
        }
    }
    
    private func scheduleNotificationsIfNeeded() {
        // BAC alert notifications
        if settingsManager.enableBACAlerts {
            notificationManager.scheduleBACNotification(bac: currentBAC)
        }
        
        // Hydration reminder
        if settingsManager.enableHydrationReminders {
            notificationManager.scheduleHydrationReminder()
        }
        
        // Schedule a morning check-in if this is the last drink of the night (heuristic)
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
    
    // MARK: - Data Persistence
    
    private func saveHydrationData() {
        UserDefaults.standard.set(waterConsumption, forKey: "waterConsumption")
        if let time = lastHydrationTime {
            UserDefaults.standard.set(time.timeIntervalSince1970, forKey: "lastHydrationTime")
        }
    }
    
    private func loadHydrationData() {
        waterConsumption = UserDefaults.standard.double(forKey: "waterConsumption")
        
        if let timeInterval = UserDefaults.standard.object(forKey: "lastHydrationTime") as? TimeInterval {
            lastHydrationTime = Date(timeIntervalSince1970: timeInterval)
        }
        
        // Reset if it's a new day
        let calendar = Calendar.current
        if let lastTime = lastHydrationTime, !calendar.isDateInToday(lastTime) {
            waterConsumption = 0
            lastHydrationTime = nil
            saveHydrationData()
        }
    }
    
    private func saveDrinkCost(_ cost: Double) {
        // Get existing costs for today
        var costs = UserDefaults.standard.array(forKey: "drinkCostsToday") as? [Double] ?? []
        costs.append(cost)
        UserDefaults.standard.set(costs, forKey: "drinkCostsToday")
        
        // Also save the date to check if we need to reset tomorrow
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastCostSaveDate")
    }
    
    private func loadDrinkCosts() {
        // Check if we need to reset (new day)
        if let lastSaveTimeInterval = UserDefaults.standard.object(forKey: "lastCostSaveDate") as? TimeInterval {
            let lastSaveDate = Date(timeIntervalSince1970: lastSaveTimeInterval)
            let calendar = Calendar.current
            
            if !calendar.isDateInToday(lastSaveDate) {
                // It's a new day, reset costs
                UserDefaults.standard.removeObject(forKey: "drinkCostsToday")
                totalDrinkCost = 0
                return
            }
        }
        
        // Load costs for today
        if let costs = UserDefaults.standard.array(forKey: "drinkCostsToday") as? [Double] {
            totalDrinkCost = costs.reduce(0, +)
        } else {
            totalDrinkCost = 0
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
