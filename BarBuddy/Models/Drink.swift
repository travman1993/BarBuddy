//
//  Drink.swift
//  BarBuddy
//

import Foundation

/**
 * Represents a single alcoholic drink consumed by the user.
 *
 * This model includes information about the type of drink, its size,
 * alcohol content, and when it was consumed.
 */
public struct Drink: Identifiable, Codable, Hashable {
    /// Unique identifier for the drink
    public let id: UUID
    
    /// The type of alcoholic beverage (beer, wine, cocktail, etc.)
    public let type: DrinkType
    
    /// Size of the drink in fluid ounces
    public let size: Double
    
    /// Alcohol percentage by volume (e.g., 5.0 for 5% ABV)
    public let alcoholPercentage: Double
    
    /// Date and time when the drink was consumed
    public let timestamp: Date
    
    /// Optional cost of the drink (for expense tracking)
    public var cost: Double?
    
    /**
     * Initializes a new Drink instance.
     *
     * - Parameters:
     *   - type: The type of alcoholic beverage
     *   - size: Size in fluid ounces
     *   - alcoholPercentage: Alcohol percentage by volume
     *   - timestamp: When the drink was consumed (defaults to current time)
     *   - cost: Optional price of the drink
     */
    public init(
        type: DrinkType,
        size: Double,
        alcoholPercentage: Double,
        timestamp: Date = Date(),
        cost: Double? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
        self.cost = cost
    }
    
    /**
     * Calculates the number of standard drinks represented by this beverage.
     *
     * In the US, a standard drink contains 0.6 fluid ounces of pure alcohol.
     */
    public var standardDrinks: Double {
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
    
    /**
     * Estimates the number of calories in the drink based on alcohol content and type.
     */
    public var estimatedCalories: Int {
        // Alcohol calories: 7 calories per gram of alcohol
        let alcoholGrams = size * (alcoholPercentage / 100) * 0.789
        let alcoholCalories = Int(alcoholGrams * 7)
        
        // Additional calories from carbs based on drink type
        let carbCalories: Int
        switch type {
        case .beer: carbCalories = Int(size * 13)
        case .wine: carbCalories = Int(size * 4)
        case .cocktail: carbCalories = Int(size * 12)
        case .shot: carbCalories = Int(size * 2)
        case .other: carbCalories = Int(size * 8)
        }
        
        return alcoholCalories + carbCalories
    }
}
