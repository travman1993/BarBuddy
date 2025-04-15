// DrinkTracker.swift - Modified Version
// DrinkTracker.swift - Enhanced Version
import Foundation
import Combine

public class DrinkTracker: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var drinks: [Drink] = []
    @Published public private(set) var userProfile: UserProfile = UserProfile()
    @Published public private(set) var standardDrinkCount: Double = 0.0
    @Published public private(set) var drinkLimit: Double = 4.0 // Default limit
    @Published public private(set) var timeUntilReset: TimeInterval = 0
    
    // MARK: - Private Properties
    private var resetTimer: Timer?
    private var lastResetDate: Date?
    
    // MARK: - Initialization
    public init() {
        loadUserProfile()
        loadSavedDrinks()
        loadDrinkLimit()
        loadLastResetDate()
        checkForNightReset() // Check immediately on init in case we need to reset
        calculateDrinkCount()
        startResetTimer()
    }
    
    deinit {
        resetTimer?.invalidate()
    }
    
    // MARK: - Drink Management
    public func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        let newDrink = Drink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage,
            timestamp: Date()
        )
        drinks.append(newDrink)
        saveDrinks()
        calculateDrinkCount()
    }
    
    public func removeDrink(_ drink: Drink) {
        if let index = drinks.firstIndex(where: { $0.id == drink.id }) {
            drinks.remove(at: index)
            saveDrinks()
            calculateDrinkCount()
        }
    }
    
    public func clearDrinks() {
        drinks.removeAll()
        saveDrinks()
        calculateDrinkCount()
    }
    
    // MARK: - User Profile Management
    public func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    // MARK: - Drink Limit Management
    public func updateDrinkLimit(_ limit: Double) {
        drinkLimit = limit
        UserDefaults.standard.set(limit, forKey: "userDrinkLimit")
    }
    
    // MARK: - Helper methods
    private func startResetTimer() {
        // Update every minute to check for 4 AM reset and recalculate time until reset
        resetTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkForNightReset()
            self?.calculateTimeUntilReset()
        }
    }
    
    private func checkForNightReset() {
            // Check if we need to reset (at 4 AM)
            let calendar = Calendar.current
            let now = Date()
            let today = calendar.startOfDay(for: now)
            
            // Current hour
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            
            // Get the last reset date
            if let lastReset = lastResetDate {
                // If the last reset was on a different day and it's past 4 AM, reset the drinks
                
                // Reset if we're on a new day AND it's past 4:00 AM
                let isNewDay = calendar.isDate(lastReset, inSameDayAs: today) == false
                let isPastResetTime = currentHour >= 4
                
                if isNewDay && isPastResetTime {
                    resetDrinkCount()
                    lastResetDate = now
                    saveLastResetDate()
                }
            } else {
                // First time, just set the reset date
                lastResetDate = now
                saveLastResetDate()
            }
            
            // Also do a direct check for 4 AM for more immediate reset
            if currentHour == 4 && currentMinute == 0 {
                resetDrinkCount()
                lastResetDate = now
                saveLastResetDate()
            }
        }
    
    private func resetDrinkCount() {
        // Clear only drinks from previous days, keeping today's drinks
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Keep only today's drinks
        drinks = drinks.filter {
            calendar.isDate($0.timestamp, inSameDayAs: today)
        }
        
        saveDrinks()
        calculateDrinkCount()
        
        // Notify via UserDefaults for Watch app
        UserDefaults.standard.set(standardDrinkCount, forKey: "currentDrinkCount")
        UserDefaults.standard.set(Date(), forKey: "lastDrinkReset")
        UserDefaults.standard.synchronize()
        
        // Also send data to Watch if WatchSessionManager is available
        WatchSessionManager.shared.sendDrinkDataToWatch(
            drinkCount: standardDrinkCount,
            drinkLimit: drinkLimit,
            timeUntilReset: timeUntilReset
        )
    }
    
    private func calculateDrinkCount() {
        // Filter recent drinks (last 24 hours)
        let recentDrinks = drinks.filter {
            Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
        }
        
        // Add up standard drinks
        standardDrinkCount = recentDrinks.reduce(0) { $0 + $1.standardDrinks }
        
        // Calculate time until reset
        calculateTimeUntilReset()
    }
    
    private func calculateTimeUntilReset() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next 4 AM
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 4
        components.minute = 0
        components.second = 0
        
        // Get today's 4 AM
        if let todayAt4AM = calendar.date(from: components) {
            // If it's already past 4 AM, add a day
            if now > todayAt4AM {
                components.day! += 1
            }
            
            // Get the reset time
            if let resetTime = calendar.date(from: components) {
                timeUntilReset = resetTime.timeIntervalSince(now)
                
                // Update notification for time until reset
                NotificationCenter.default.post(name: NSNotification.Name("timeUntilResetUpdated"), object: nil)
            }
        }
    }
    
    // MARK: - Persistence Methods
    private func saveDrinks() {
        if let encoded = try? JSONEncoder().encode(drinks) {
            UserDefaults.standard.set(encoded, forKey: "savedDrinks")
        }
    }
    
    private func loadSavedDrinks() {
        if let savedDrinks = UserDefaults.standard.data(forKey: "savedDrinks"),
           let decodedDrinks = try? JSONDecoder().decode([Drink].self, from: savedDrinks) {
            drinks = decodedDrinks
        }
    }
    
    private func saveUserProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
    }
    
    private func loadUserProfile() {
        if let savedProfile = UserDefaults.standard.data(forKey: "userProfile"),
           let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
            userProfile = decodedProfile
        }
    }
    
    private func loadDrinkLimit() {
        let limit = UserDefaults.standard.double(forKey: "userDrinkLimit")
        if limit > 0 {
            drinkLimit = limit
        }
    }
    
    private func saveLastResetDate() {
        UserDefaults.standard.set(lastResetDate, forKey: "lastDrinkReset")
    }
    
    private func loadLastResetDate() {
        lastResetDate = UserDefaults.standard.object(forKey: "lastDrinkReset") as? Date
    }
    
    // MARK: - Status Methods
    public func getSafetyStatus() -> SafetyStatus {
        if standardDrinkCount >= drinkLimit {
            return .unsafe
        } else if standardDrinkCount >= drinkLimit * 0.75 {
            return .borderline
        } else {
            return .safe
        }
    }
    
    // MARK: - Analytics
    public func getDailyDrinkStats(for date: Date = Date()) -> (totalDrinks: Int, standardDrinks: Double) {
        let calendar = Calendar.current
        let dayDrinks = drinks.filter {
            calendar.isDate($0.timestamp, inSameDayAs: date)
        }
        
        return (
            totalDrinks: dayDrinks.count,
            standardDrinks: dayDrinks.reduce(0) { $0 + $1.standardDrinks }
        )
    }
}
