//
//  Theme.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
import SwiftUI

// MARK: - Color Extension
extension Color {
    // Base Background Colors
    static let appBackground = Color("AppBackground")
    static let appCardBackground = Color("AppCardBackground")
    
    // Text Colors
    static let appTextPrimary = Color("AppTextPrimary")
    static let appTextSecondary = Color("AppTextSecondary")
    
    // Accent and Interaction Colors
    static let accent = Color("AccentColor")
    static let accentDark = Color("AccentColorDark")
    
    // Status Colors
    static let safe = Color("SafeColor")
    static let warning = Color("WarningColor")
    static let danger = Color("DangerColor")
    
    // Drink Type Colors
    static let beerColor = Color("BeerColor")
    static let wineColor = Color("WineColor")
    static let cocktailColor = Color("CocktailColor")
    static let shotColor = Color("ShotColor")
    
    // Background Tints
    static let safeBackground = safe.opacity(0.1)
    static let warningBackground = warning.opacity(0.1)
    static let dangerBackground = danger.opacity(0.1)
    
    // Separator
    static let appSeparator = Color("AppSeparator")
}

// MARK: - View Extensions for Consistent Styling
extension View {
    // Adaptive layout for tablets and phones
    func adaptiveLayout() -> some View {
        self.modifier(AdaptiveLayoutModifier())
    }
    
    // Card-like styling
    func cardStyle() -> some View {
        self.padding()
            .background(Color.appCardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // Accent button style
    func accentButtonStyle() -> some View {
        self.padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.accent, Color.accentDark]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(30)
            .shadow(color: Color.accent.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

// MARK: - Adaptive Layout Modifier
struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: horizontalSizeClass == .regular ? 700 : .infinity)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Typography Extensions
extension Text {
    // Primary title style
    func titleStyle() -> some View {
        self.font(.title)
            .fontWeight(.bold)
            .foregroundColor(.appTextPrimary)
    }
    
    // Headline style
    func headlineStyle() -> some View {
        self.font(.headline)
            .foregroundColor(.appTextPrimary)
    }
    
    // Secondary text style
    func secondaryStyle() -> some View {
        self.font(.subheadline)
            .foregroundColor(.appTextSecondary)
    }
}

// MARK: - Color Scheme Handling
struct AppColorScheme {
    static func setupAppearance() {
        // Customize navigation bar appearance
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
        
        // Tab bar customization
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor(Color.appCardBackground)
        tabBarAppearance.unselectedItemTintColor = UIColor(Color.appTextSecondary)
        tabBarAppearance.tintColor = UIColor(Color.accent)
    }
}

// MARK: - Drink Type Color Helpers
func getDrinkTypeColor(_ type: DrinkType) -> Color {
    switch type {
    case .beer: return .beerColor
    case .wine: return .wineColor
    case .cocktail: return .cocktailColor
    case .shot: return .shotColor
    case .other: return .appTextSecondary
    }
}

// MARK: - Safety Status Color Helpers
func getSafetyStatusColor(_ status: SafetyStatus) -> Color {
    switch status {
    case .safe: return .safe
    case .borderline: return .warning
    case .unsafe: return .danger
    }
}
