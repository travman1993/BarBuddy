//
//  DrinkTracker.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation
import Combine

public class DrinkTracker: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var drinks: [Drink] = []
    @Published public private(set) var userProfile: UserProfile = UserProfile()
    @Published public private(set) var currentBAC: Double = 0.0
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
    
    public func removeDrink(_ drink: Drink) {
        if let index = drinks.firstIndex(where: { $0.id == drink.id }) {
            drinks.remove(at: index)
            saveDrinks()
            calculateBAC()
        }
    }
    
    public func clearDrinks() {
        drinks.removeAll()
        saveDrinks()
        calculateBAC()
    }
    
    // MARK: - User Profile Management
    public func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
        calculateBAC()
    }
    
    // MARK: - BAC Calculation
    private func startBACUpdateTimer() {
        // Update BAC every minute
        bacUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.calculateBAC()
        }
    }
    
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
        
        // Comprehensive BAC calculation
        let totalAlcoholGrams = calculateTotalAlcohol(from: recentDrinks)
        let bodyWaterConstant = userProfile.gender == .male ? 0.68 : 0.55
        let weightInGrams = userProfile.weight * 453.592 // Convert lbs to grams
        
        // Initial BAC calculation using Widmark formula
        var estimatedBAC = totalAlcoholGrams / (weightInGrams * bodyWaterConstant) * 100
        
        // Time-based BAC reduction
        for drink in recentDrinks {
            let hoursSinceDrink = Date().timeIntervalSince(drink.timestamp) / 3600
            // Subtract alcohol elimination rate
            estimatedBAC -= alcoholEliminationRate * hoursSinceDrink
        }
        
        // Ensure BAC doesn't go negative
        currentBAC = max(0, estimatedBAC)
        
        // Calculate time until sober
        calculateTimeUntilSober()
    }
    
    private func calculateTotalAlcohol(from drinks: [Drink]) -> Double {
        return drinks.reduce(0) { sum, drink in
            // Calculate alcohol in grams
            // Size (oz) * Alcohol % * Density of ethanol * Volume conversion
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789 * 29.5735
            return sum + alcoholGrams
        }
    }
    
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
