//
//  Theme.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/1/25.
//
import SwiftUI

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
                    gradient: Gradient(colors: [Color("AccentColor"), Color("AccentColorDark")]),
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
    case .beer: return Color("BeerColor")
    case .wine: return Color("WineColor")
    case .cocktail: return Color("CocktailColor")
    case .shot: return Color("ShotColor")
    case .other: return Color("AppTextSecondary")
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
