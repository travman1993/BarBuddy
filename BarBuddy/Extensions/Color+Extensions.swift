//
//  Color+Extensions.swift
//  BarBuddy
//

import SwiftUI

/**
 * Extensions to the Color type for app-specific color definitions.
 *
 * This provides a centralized way to reference custom colors throughout the app
 * and ensures consistent theming.
 */
extension Color {
    // MARK: - App Theme Colors
    
    /// Primary accent color
    static let accent = Color("AccentColor")
    
    /// Darker variant of the accent color for gradients
    static let accentDark = Color("AccentColorDark")
    
    /// Main background color for app screens
    static let appBackground = Color("AppBackground")
    
    /// Background color for cards and content areas
    static let appCardBackground = Color("AppCardBackground")
    
    /// Color for dividers and separators
    static let appSeparator = Color("AppSeparator")
    
    /// Primary text color
    static let appTextPrimary = Color("AppTextPrimary")
    
    /// Secondary text color for labels and captions
    static let appTextSecondary = Color("AppTextSecondary")
    
    // MARK: - Status Colors
    
    /// Color for safe status indicators (below 0.04 BAC)
    static let safe = Color.green
    
    /// Color for warning status indicators (0.04-0.08 BAC)
    static let warning = Color.orange
    
    /// Color for danger status indicators (above 0.08 BAC)
    static let danger = Color.red
    
    // MARK: - Drink Type Colors
    
    /// Color associated with beer drinks
    static let beerColor = Color("BeerColor")
    
    /// Color associated with wine drinks
    static let wineColor = Color("WineColor")
    
    /// Color associated with cocktail drinks
    static let cocktailColor = Color("CocktailColor")
    
    /// Color associated with shot drinks
    static let shotColor = Color("ShotColor")
    
    // MARK: - Background Tints
    
    /// Light background tint for safe status
    static let safeBackground = safe.opacity(0.1)
    
    /// Light background tint for warning status
    static let warningBackground = warning.opacity(0.1)
    
    /// Light background tint for danger status
    static let dangerBackground = danger.opacity(0.1)
}
