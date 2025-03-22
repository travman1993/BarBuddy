//
//  DrinkTracker.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation
import Combine
import SwiftUI

public class DrinkTracker: ObservableObject {
    // Published properties to update the UI when changed
    @Published public var drinks: [Drink] = []
    @Published public var userProfile: UserProfile = UserProfile()
    @Published public var currentBAC: Double = 0.0
    @Published public var timeUntilSober: TimeInterval = 0
    
    // Timer to regularly update BAC
    private var bacUpdateTimer: Timer?
    
    public init() {
        // Load user profile from UserDefaults or use default
        loadUserProfile()
        // Load any saved drinks from last session
        loadSavedDrinks()
        // Start BAC calculation timer
        startBACUpdateTimer()
    }
    
    deinit {
        bacUpdateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
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
    
    public func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
        calculateBAC()
    }
    
    // MARK: - Private Methods
    
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
        
        // If no drinks in last 24 hours, BAC is 0
        if recentDrinks.isEmpty {
            currentBAC = 0.0
            timeUntilSober = 0
            return
        }
        
        // Calculate total alcohol consumed (in grams)
        let totalAlcoholGrams = recentDrinks.reduce(0) { sum, drink in
            // Size in oz * alcohol % * 0.789 (density of ethanol) * 29.5735 (ml per oz)
            let alcoholGrams = drink.size * (drink.alcoholPercentage / 100) * 0.789 * 29.5735
            return sum + alcoholGrams
        }
        
        // Calculate BAC using Widmark formula
        let bodyWaterConstant = userProfile.gender == .male ? 0.68 : 0.55
        let weightInGrams = userProfile.weight * 453.592 // Convert lbs to grams
        
        // Initial BAC without time adjustment
        var bac = totalAlcoholGrams / (weightInGrams * bodyWaterConstant) * 100
        
        // Adjust BAC for time elapsed (alcohol metabolism)
        for drink in recentDrinks {
            let hoursSinceDrink = Date().timeIntervalSince(drink.timestamp) / 3600
            // Subtract alcohol elimination rate (0.015% per hour)
            bac -= 0.015 * hoursSinceDrink
        }
        
        // BAC can't be negative
        bac = max(0, bac)
        
        // Update published values
        currentBAC = bac
        
        // Calculate time until sober (BAC < 0.01)
        if bac > 0.01 {
            // Time (hours) = BAC / 0.015
            timeUntilSober = (bac - 0.01) / 0.015 * 3600 // Convert to seconds
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
}
