//
//  Theme.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
// Theme.swift - Add to your project
import SwiftUI

// Color extension to create a central place for app colors
extension Color {
    // App Colors
    static let appBackground = Color("AppBackground", bundle: nil) // #222222 in dark, #F8F9FA in light
    static let appCardBackground = Color("AppCardBackground", bundle: nil) // #1A1A1A in dark, #FFFFFF in light
    static let appTextPrimary = Color("AppTextPrimary", bundle: nil) // #F8F9FA in dark, #222222 in light
    static let appTextSecondary = Color("AppTextSecondary", bundle: nil) // #A0A0A0 in dark, #6c757d in light
    static let appSeparator = Color("AppSeparator", bundle: nil) // #2A2A2A in dark, #e9ecef in light
    
    // Accent Colors
    static let accent = Color("AccentColor", bundle: nil) // #A97442 (whiskey brown)
    static let accentDark = Color("AccentColorDark", bundle: nil) // #8B5E3C (darker whiskey brown)
    
    // Status Colors
    static let safe = Color("SafeColor", bundle: nil) // #0EBF00 (green)
    static let warning = Color("WarningColor", bundle: nil) // #FFCC00 (yellow)
    static let danger = Color("DangerColor", bundle: nil) // #FF4D00 (orange-red)
    
    // Drink Type Colors
    static let beerColor = Color("BeerColor", bundle: nil) // #DAA520 (golden)
    static let wineColor = Color("WineColor", bundle: nil) // #8B0000 (burgundy)
    static let cocktailColor = Color("CocktailColor", bundle: nil) // #1E90FF (blue)
    static let shotColor = Color("ShotColor", bundle: nil) // #9932CC (purple)
    
    // Background tints
    static let safeBackground = Color.safe.opacity(0.1)
    static let warningBackground = Color.warning.opacity(0.1)
    static let dangerBackground = Color.danger.opacity(0.1)
}

// This function creates the necessary color assets for your project
// Must be called once to set up your Color Assets catalog
func createColorAssets() {
    // This is just a helper to remind developers to create the color assets
    print("""
    Please create the following color assets in your asset catalog:
    
    AppBackground:
    - Dark: #222222
    - Light: #F8F9FA
    
    AppCardBackground:
    - Dark: #1A1A1A
    - Light: #FFFFFF
    
    AppTextPrimary:
    - Dark: #F8F9FA
    - Light: #222222
    
    AppTextSecondary:
    - Dark: #A0A0A0
    - Light: #6c757d
    
    AppSeparator:
    - Dark: #2A2A2A
    - Light: #e9ecef
    
    AccentColor:
    - Universal: #A97442
    
    AccentColorDark:
    - Universal: #8B5E3C
    
    SafeColor:
    - Universal: #0EBF00
    
    WarningColor:
    - Universal: #FFCC00
    
    DangerColor:
    - Universal: #FF4D00
    
    BeerColor:
    - Universal: #DAA520
    
    WineColor:
    - Universal: #8B0000
    
    CocktailColor:
    - Universal: #1E90FF
    
    ShotColor:
    - Universal: #9932CC
    """)
}

// Define styles for consistent UI elements
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.accent, Color.accentDark]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(30)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .shadow(color: Color.accent.opacity(0.5), radius: 5, x: 0, y: 3)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
}

// Consistent text styles
extension Text {
    func titleStyle() -> Text {
        self.font(.title)
            .fontWeight(.bold)
            .foregroundColor(.appTextPrimary)
    }
    
    func headlineStyle() -> Text {
        self.font(.headline)
            .foregroundColor(.appTextPrimary)
    }
    
    func captionStyle() -> Text {
        self.font(.caption)
            .foregroundColor(.appTextSecondary)
    }
    
    func accentCaptionStyle() -> Text {
        self.font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.accent)
    }
}

// Style for section headers
struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.accent)
            .padding(.bottom, 5)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        self.modifier(SectionHeaderStyle())
    }
}

// Add to your Theme.swift
extension View {
    func cardStyle() -> some View {
        self.padding()
            .background(Color.appCardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    func accentButtonStyle() -> some View {
        self.padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.accent, Color.accentDark]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white)
            .cornerRadius(30)
    }
}

// Text style extensions
extension Text {
    func headlineStyle() -> Text {
        self.font(.headline)
            .foregroundColor(.appTextPrimary)
    }
    
    func captionStyle() -> Text {
        self.font(.caption)
            .foregroundColor(.appTextSecondary)
    }
}

// Helper for creating gradient backgrounds for different drink types
func drinkTypeGradient(for type: DrinkType) -> LinearGradient {
    switch type {
    case .beer:
        return LinearGradient(gradient: Gradient(colors: [Color.beerColor, Color.beerColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
    case .wine:
        return LinearGradient(gradient: Gradient(colors: [Color.wineColor, Color.wineColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
    case .cocktail:
        return LinearGradient(gradient: Gradient(colors: [Color.cocktailColor, Color.cocktailColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
    case .shot:
        return LinearGradient(gradient: Gradient(colors: [Color.shotColor, Color.shotColor.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
    case .other:
        return LinearGradient(gradient: Gradient(colors: [Color.appTextSecondary, Color.appTextSecondary.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
    }
}
