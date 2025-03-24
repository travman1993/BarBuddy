//
//  DrinkTrackerWatch.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import Combine

public class DrinkTracker: ObservableObject {
    // Published properties to update the UI when changed
    @Published public var drinks: [Drink] = []
    @Published public var currentBAC: Double = 0.0
    @Published public var timeUntilSober: TimeInterval = 0
    
    // Default user profile with placeholder values
    private var userProfile: UserProfile = UserProfile()
    
    public init() {
        // Load any saved drinks from UserDefaults
        loadSavedDrinks()
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
    
    // MARK: - Private Methods
    
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
    
    // MARK: - Special Methods for WatchOS
    
    // Update BAC and time based on data from iPhone
    public func updateBACData(bac: Double, timeUntilSober: TimeInterval) {
        self.currentBAC = bac
        self.timeUntilSober = timeUntilSober
    }
}

// MARK: - Essential Data Models
// These duplicate the structures from ModelStructures.swift to ensure the Watch app has access

public enum DrinkType: String, Codable, CaseIterable {
    case beer = "Beer"
    case wine = "Wine"
    case cocktail = "Cocktail"
    case shot = "Shot"
    case other = "Other"
    
    public var defaultSize: Double {
        switch self {
        case .beer: return 12.0 // 12 oz
        case .wine: return 5.0 // 5 oz
        case .cocktail: return 4.0 // 4 oz
        case .shot: return 1.5 // 1.5 oz
        case .other: return 8.0 // 8 oz default
        }
    }
    
    public var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0 // 5%
        case .wine: return 12.0 // 12%
        case .cocktail: return 15.0 // 15%
        case .shot: return 40.0 // 40%
        case .other: return 10.0 // 10% default
        }
    }
    
    public var icon: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍸"
        case .shot: return "🥃"
        case .other: return "🍹"
        }
    }
}

// Enum for biological gender (used for BAC calculation)
public enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

// Struct for a single drink
public struct Drink: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: DrinkType
    public let size: Double // in fluid ounces
    public let alcoholPercentage: Double // as a percentage (e.g., 5.0 for 5%)
    public let timestamp: Date
    
    public init(type: DrinkType, size: Double, alcoholPercentage: Double, timestamp: Date) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
    }
    
    // Calculate standard drinks
    // A standard drink is defined as 0.6 fl oz of pure alcohol
    public var standardDrinks: Double {
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
}

// Struct for user profile
public struct UserProfile: Codable, Hashable {
    public var weight: Double // in pounds
    public var gender: Gender
    
    public init(weight: Double = 160.0, gender: Gender = .male) {
        self.weight = weight
        self.gender = gender
    }
}

// Struct for emergency contact
public struct EmergencyContact: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var phoneNumber: String
    public var relationshipType: String
    public var sendAutomaticTexts: Bool
    
    public init(name: String, phoneNumber: String, relationshipType: String, sendAutomaticTexts: Bool = false) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationshipType = relationshipType
        self.sendAutomaticTexts = sendAutomaticTexts
    }
}

// Enum for safety status
public enum SafetyStatus: String, Codable, Hashable {
    case safe = "Safe to Drive"
    case borderline = "Borderline"
    case unsafe = "DO NOT DRIVE"
    
    public var color: String {
        switch self {
        case .safe: return "green"
        case .borderline: return "yellow"
        case .unsafe: return "red"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
}
