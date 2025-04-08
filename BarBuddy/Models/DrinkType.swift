//
//  DrinkType.swift
//  BarBuddy
//

import SwiftUI

/**
 * Represents the various types of alcoholic beverages that can be tracked.
 *
 * Each type includes default values for standard serving sizes and
 * typical alcohol content to simplify drink logging.
 */
public enum DrinkType: String, Codable, CaseIterable, Hashable {
    /// Beer and similar malt beverages
    case beer = "Beer"
    
    /// Wine (red, white, rosé, sparkling, etc.)
    case wine = "Wine"
    
    /// Mixed drinks and prepared cocktails
    case cocktail = "Cocktail"
    
    /// Spirits/liquor consumed as shots
    case shot = "Shot"
    
    /// Any other alcoholic beverage that doesn't fit the standard categories
    case other = "Other"
    
    /**
     * Default serving size in fluid ounces for each drink type.
     */
    public var defaultSize: Double {
        switch self {
        case .beer: return 12.0     // Standard can
        case .wine: return 5.0      // Standard wine pour
        case .cocktail: return 4.0  // Standard cocktail
        case .shot: return 1.5      // Standard shot
        case .other: return 8.0     // Default for other drinks
        }
    }
    
    /**
     * Default alcohol percentages for each drink type.
     */
    public var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0      // Average beer
        case .wine: return 12.0     // Average wine
        case .cocktail: return 15.0 // Average cocktail
        case .shot: return 40.0     // Average spirits
        case .other: return 10.0    // Default for other
        }
    }
    
    /**
     * Emoji representation for UI display.
     */
    public var icon: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍸"
        case .shot: return "🥃"
        case .other: return "🍹"
        }
    }
    
     public var color: Color {
         switch self {
         case .beer: return Color("BeerColor")
         case .wine: return Color("WineColor")
         case .cocktail: return Color("CocktailColor")
         case .shot: return Color("ShotColor")
         case .other: return Color("AppTextSecondary")
         }
     }
}
