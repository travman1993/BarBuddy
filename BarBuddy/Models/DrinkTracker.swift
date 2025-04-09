//
//  DrinkTracker.swift
//  BarBuddy
//

import Foundation
import Combine

/**
 * The DrinkTracker class is the core model responsible for tracking and calculating blood alcohol content (BAC).
 *
 * It maintains a list of drinks consumed, calculates the current BAC based on user profile data,
 * and provides information about when the user will be sober.
 *
 * - Important: BAC calculations are estimates only and should not be used to determine if someone is legally able to drive.
 */
public class DrinkTracker: ObservableObject {
    // MARK: - Published Properties
    
    /// A list of all drinks logged by the user.
    @Published public private(set) var drinks: [Drink] = []
    
    /// The user's profile containing weight, gender, and other personal information used for BAC calculations.
    @Published public private(set) var userProfile: UserProfile = UserProfile()
    
    /// The current estimated blood alcohol content (BAC) as calculated based on drinks consumed and user profile.
    @Published public private(set) var currentBAC: Double = 0.0
    
    /// Estimated time (in seconds) until the user's BAC will drop below 0.01.
    @Published public private(set) var timeUntilSober: TimeInterval = 0
    
    // MARK: - Private Properties
    private var bacUpdateTimer: Timer?
    private let alcoholEliminationRate: Double = 0.015 // Standard elimination rate
    
    // MARK: - Initialization
    public init() {
        loadUserProfile()
        loadSavedDrinks()
        startBACUpdateTimer()
    }
    
    deinit {
        bacUpdateTimer?.invalidate()
    }
    
    // MARK: - Drink Management
    
    /**
     * Adds a new alcoholic drink to the tracker and recalculates BAC.
     *
     * - Parameters:
     *   - type: The type of drink (beer, wine, cocktail, shot, other)
     *   - size: The size of the drink in fluid ounces
     *   - alcoholPercentage: The alcohol percentage by volume (ABV)
     */
    public func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        let newDrink = Drink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage,
            timestamp: Date()
        )
        drinks.append(newDrink)
        saveDrinks()
        calculateBAC()
    }
    
    /**
     * Removes a drink from the history and recalculates BAC.
     *
     * - Parameter drink: The specific drink to remove.
     */
    public func removeDrink(_ drink: Drink) {
        if let index = drinks.firstIndex(where: { $0.id == drink.id }) {
            drinks.remove(at: index)
            saveDrinks()
            calculateBAC()
        }
    }
    
    /**
     * Clears all drinks from the history and resets BAC to zero.
     */
    public func clearDrinks() {
        drinks.removeAll()
        saveDrinks()
        calculateBAC()
    }
    
    // MARK: - User Profile Management
    
    /**
     * Updates the user's profile information and recalculates BAC.
     *
     * - Parameter profile: The new UserProfile containing updated information.
     */
    public func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
        calculateBAC()
    }
    
    // MARK: - BAC Calculation Methods
    
    /**
     * Starts a timer to periodically update BAC calculations.
     */
    private func startBACUpdateTimer() {
        // Update BAC every minute
        bacUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.calculateBAC()
        }
    }
    
    /**
     * Calculates the current BAC based on drinks consumed, user profile, and elapsed time.
     * This method uses the Widmark formula with adjustments for time-based elimination.
     */
    private func calculateBAC() {
        // Filter out drinks older than 24 hours
        let recentDrinks = drinks.filter {
            Calendar.current.dateComponents([.hour], from: $0.timestamp, to: Date()).hour! < 24
        }
        
        // If no recent drinks, BAC is 0
        guard !recentDrinks.isEmpty else {
            currentBAC = 0.0
            timeUntilSober = 0
            return
        }
        
        // Widmark formula implementation with proper time-based processing
        var currentBac = 0.0
        let bodyWaterConstant = userProfile.gender == .male ? 0.68 : 0.55
        let weightInGrams = userProfile.weight * 453.592 // Convert lbs to grams
        
        // Process each drink individually
        for drink in recentDrinks {
            // Calculate the initial BAC contribution from this drink
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789 * 29.5735
            let drinkBac = alcoholGrams / (weightInGrams * bodyWaterConstant) * 100
            
            // Calculate how much of this drink has been metabolized
            let hoursSinceDrink = Date().timeIntervalSince(drink.timestamp) / 3600
            let bacRemaining = max(0, drinkBac - (alcoholEliminationRate * hoursSinceDrink))
            
            // Add this drink's remaining BAC to the total
            currentBac += bacRemaining
        }
        
        // Set final BAC
        currentBAC = max(0, currentBac)
        
        // Calculate time until sober
        calculateTimeUntilSober()
    }
    
    /**
     * Calculates the total alcohol in grams from a collection of drinks.
     */
    private func calculateTotalAlcohol(from drinks: [Drink]) -> Double {
        return drinks.reduce(0) { sum, drink in
            // Calculate alcohol in grams
            // Size (oz) * Alcohol % * Density of ethanol * Volume conversion
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789 * 29.5735
            return sum + alcoholGrams
        }
    }
    
    /**
     * Calculates the estimated time until the user's BAC will drop below 0.01%.
     */
    private func calculateTimeUntilSober() {
        // Calculate time to reach 0.01 BAC
        if currentBAC > 0.01 {
            // Time to sober = (Current BAC - 0.01) / Elimination Rate
            timeUntilSober = max(0, (currentBAC - 0.01) / alcoholEliminationRate * 3600)
        } else {
            timeUntilSober = 0
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
            calculateBAC()
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
    
    // MARK: - Advanced Analytics
    
    /**
     * Returns statistics about drinks consumed on a specific day.
     *
     * - Parameter date: The date to analyze (defaults to today)
     * - Returns: Statistics about drink consumption for the day
     */
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
    
    // MARK: - Safety Methods
    
    /**
     * Returns the current safety status based on BAC level.
     */
    public func getSafetyStatus() -> SafetyStatus {
        if currentBAC < 0.04 {
            return .safe
        } else if currentBAC < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }
}
