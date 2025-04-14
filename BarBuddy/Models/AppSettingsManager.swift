//
//  AppSettingsManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import SwiftUI
import Combine

class AppSettingsManager: ObservableObject {
    // Singleton instance
    static let shared = AppSettingsManager()
    
    // MARK: - User Profile Settings
    @Published var weight: Double = 160.0
    @Published var gender: Gender = .male
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 10
    
    // MARK: - Appearance Settings
    @Published var useMetricUnits: Bool = false
    @Published var dynamicTypeSize: DynamicTypeSize = .medium
    @Published var colorScheme: ColorScheme? = nil
    
    // MARK: - Tracking Settings
    @Published var trackDrinkHistory: Bool = true
    @Published var trackLocations: Bool = false
    @Published var saveAlcoholSpending: Bool = true
    @Published var saveDrinksFor: Int = 90 // Days
    
    // MARK: - Notification Settings
    @Published var enableDrinkAlerts: Bool = true
    @Published var enableHydrationReminders: Bool = true
    @Published var enableDrinkingDurationAlerts: Bool = true
    @Published var enableMorningCheckIns: Bool = false

    // MARK: - Privacy Settings
    @Published var enablePasscodeProtection: Bool = false
    @Published var useBiometricAuthentication: Bool = false
    @Published var allowDataSharing: Bool = false

    // MARK: - Watch Settings
    @Published var syncWithAppleWatch: Bool = true
    @Published var watchQuickAdd: Bool = true
    @Published var watchComplication: Bool = true

    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()

    // Private initializer for singleton
    private init() {
        loadSettings()
        setupBindings()
        applyAppearanceSettings()
    }

    // MARK: - Setup Methods
    private func setupBindings() {
        setupBinding(for: $weight)
        setupBinding(for: $gender)
        setupBinding(for: $heightFeet)
        setupBinding(for: $heightInches)
        setupBinding(for: $useMetricUnits)
        setupBinding(for: $dynamicTypeSize)
        
        // Special handling for color scheme
        $colorScheme
            .sink { [weak self] _ in
                self?.applyAppearanceSettings()
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        setupBinding(for: $trackDrinkHistory)
        setupBinding(for: $trackLocations)
        setupBinding(for: $saveAlcoholSpending)
        setupBinding(for: $saveDrinksFor)
        setupBinding(for: $enableDrinkAlerts)
        setupBinding(for: $enableHydrationReminders)
        setupBinding(for: $enableDrinkingDurationAlerts)
        setupBinding(for: $enableMorningCheckIns)
        setupBinding(for: $enablePasscodeProtection)
        setupBinding(for: $useBiometricAuthentication)
        setupBinding(for: $allowDataSharing)
        setupBinding(for: $syncWithAppleWatch)
        setupBinding(for: $watchQuickAdd)
        setupBinding(for: $watchComplication)
    }

    // Helper method for setting up a binding
    private func setupBinding<T>(for publisher: Published<T>.Publisher) {
        publisher
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Loading
    private func loadSettings() {
        // User Profile
        weight = UserDefaults.standard.double(forKey: "userWeight")
        if weight == 0 { weight = 160.0 }
        
        let genderString = UserDefaults.standard.string(forKey: "userGender") ?? "male"
        gender = genderString == "male" ? .male : .female
        
        heightFeet = UserDefaults.standard.integer(forKey: "userHeightFeet")
        if heightFeet == 0 { heightFeet = 5 }
        
        heightInches = UserDefaults.standard.integer(forKey: "userHeightInches")
        if heightInches == 0 { heightInches = 10 }
        
        // Appearance Settings
        useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
        
        // Color Scheme
        let colorSchemeRawValue = UserDefaults.standard.integer(forKey: "colorScheme")
        colorScheme = colorSchemeRawValue == 1 ? .dark :
                      (colorSchemeRawValue == 2 ? .light : nil)
        
        // Other settings loading continues similarly...
    }
    
    // MARK: - Settings Saving
    func saveSettings() {
        // User Profile
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(gender.rawValue.lowercased(), forKey: "userGender")
        UserDefaults.standard.set(heightFeet, forKey: "userHeightFeet")
        UserDefaults.standard.set(heightInches, forKey: "userHeightInches")
        
        // Appearance Settings
        UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits")
        
        // Color Scheme
        let colorSchemeValue = colorScheme == .dark ? 1 :
                                (colorScheme == .light ? 2 : 0)
        UserDefaults.standard.set(colorSchemeValue, forKey: "colorScheme")
        
        // Trigger a save and sync
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Appearance Management
    func applyAppearanceSettings() {
        // Apply color scheme
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                scenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.overrideUserInterfaceStyle = {
                                switch self.colorScheme {
                                case .dark: return .dark
                                case .light: return .light
                                case nil: return .unspecified
                                case .some(_): return .unspecified  // Add a return statement here
                                }
                            }()
                        }
                    }
                }
            }
        }
        
        // Apply navigation and tab bar styles
        AppColorScheme.setupAppearance()
    }
    
    // MARK: - Utility Methods
    func getUserHeight() -> String {
        if useMetricUnits {
            // Convert to centimeters
            let totalInches = (heightFeet * 12) + heightInches
            let centimeters = Int(Double(totalInches) * 2.54)
            return "\(centimeters) cm"
        } else {
            return "\(heightFeet)' \(heightInches)\""
        }
    }
    
    func getFormattedWeight() -> String {
        if useMetricUnits {
            // Convert to kilograms
            let kilograms = Int(weight * 0.453592)
            return "\(kilograms) kg"
        } else {
            return "\(Int(weight)) lbs"
        }
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        // Reset all settings to default values
        weight = 160.0
        gender = .male
        heightFeet = 5
        heightInches = 10
        
        useMetricUnits = false
        colorScheme = nil
        
        trackDrinkHistory = true
        trackLocations = false
        saveAlcoholSpending = true
        saveDrinksFor = 90
        
        enableHydrationReminders = true
        enableDrinkingDurationAlerts = true
        enableMorningCheckIns = false
        
        enablePasscodeProtection = false
        useBiometricAuthentication = false
        allowDataSharing = false
        
        syncWithAppleWatch = true
        watchQuickAdd = true
        watchComplication = true
        
        // Save and apply settings
        saveSettings()
        applyAppearanceSettings()
    }
}

// MARK: - Color Scheme Extension
extension AppSettingsManager {
    /// Toggles between light and dark modes
    func toggleColorScheme() {
        switch colorScheme {
        case .light:
            colorScheme = .dark
        case .dark:
            colorScheme = nil // System default
        case nil:
            colorScheme = .light
        case .some(_):
            // This case shouldn't actually return anything
            break  // Do nothing, or handle as needed
        }
    }
}
