//
//  AppSettingsManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import SwiftUI
import Combine

private extension UserDefaults {
    func contains(key: String) -> Bool {
        return self.object(forKey: key) != nil
    }
}

class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()
    
    // User profile settings
    @Published var weight: Double = 160.0
    @Published var gender: Gender = .male
    @Published var heightFeet: Int = 5
    @Published var heightInches: Int = 10
    
    // Tracking settings
    @Published var trackDrinkHistory: Bool = true
    @Published var trackLocations: Bool = false
    @Published var saveAlcoholSpending: Bool = true
    @Published var saveDrinksFor: Int = 90 // Days
    
    // Notification settings
    @Published var enableBACAlerts: Bool = true
    @Published var enableHydrationReminders: Bool = true
    @Published var enableDrinkingDurationAlerts: Bool = true
    @Published var enableMorningCheckIns: Bool = false
    
    // Privacy settings
    @Published var enablePasscodeProtection: Bool = false
    @Published var useBiometricAuthentication: Bool = false
    @Published var allowDataSharing: Bool = false
    
    // Display settings
    @Published var useMetricUnits: Bool = false
    @Published var enableDarkMode: Bool = false
    @Published var alwaysShowBAC: Bool = true
    
    // Watch settings
    @Published var syncWithAppleWatch: Bool = true
    @Published var watchQuickAdd: Bool = true
    @Published var watchComplication: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
        setupBindings()
        applyAppearanceSettings()
    }
    
    private func setupBindings() {
        // Automatically save settings when any published property changes
        $weight.debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        $gender.debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        $heightFeet.debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        $heightInches.debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
        
        // Add similar bindings for all other properties
        $trackDrinkHistory.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $trackLocations.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $saveAlcoholSpending.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $saveDrinksFor.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        
        $enableBACAlerts.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableHydrationReminders.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableDrinkingDurationAlerts.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $enableMorningCheckIns.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        
        $enablePasscodeProtection.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $useBiometricAuthentication.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $allowDataSharing.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        
        $useMetricUnits.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        
        // When dark mode setting changes, apply it immediately
        $enableDarkMode.sink { [weak self] _ in
            self?.saveSettings()
            self?.applyAppearanceSettings()
        }.store(in: &cancellables)
        
        $alwaysShowBAC.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        
        $syncWithAppleWatch.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $watchQuickAdd.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
        $watchComplication.sink { [weak self] _ in self?.saveSettings() }.store(in: &cancellables)
    }
    
    func loadSettings() {
        // User profile
        weight = UserDefaults.standard.double(forKey: "userWeight")
        if weight == 0 { weight = 160.0 } // Default value if not set
        
        let genderString = UserDefaults.standard.string(forKey: "userGender") ?? "male"
        gender = genderString == "male" ? .male : .female
        
        heightFeet = UserDefaults.standard.integer(forKey: "userHeightFeet")
        if heightFeet == 0 { heightFeet = 5 } // Default value
        
        heightInches = UserDefaults.standard.integer(forKey: "userHeightInches")
        if heightInches == 0 { heightInches = 10 } // Default value
        
        // Tracking settings
        trackDrinkHistory = UserDefaults.standard.bool(forKey: "trackDrinkHistory")
        if !UserDefaults.standard.contains(key: "trackDrinkHistory") { trackDrinkHistory = true } // Default
        
        trackLocations = UserDefaults.standard.bool(forKey: "trackLocations")
        saveAlcoholSpending = UserDefaults.standard.bool(forKey: "saveAlcoholSpending")
        if !UserDefaults.standard.contains(key: "saveAlcoholSpending") { saveAlcoholSpending = true } // Default
        
        saveDrinksFor = UserDefaults.standard.integer(forKey: "saveDrinksFor")
        if saveDrinksFor == 0 { saveDrinksFor = 90 } // Default to 90 days
        
        // Notification settings
        enableBACAlerts = UserDefaults.standard.bool(forKey: "enableBACAlerts")
        if !UserDefaults.standard.contains(key: "enableBACAlerts") { enableBACAlerts = true } // Default
        
        enableHydrationReminders = UserDefaults.standard.bool(forKey: "enableHydrationReminders")
        if !UserDefaults.standard.contains(key: "enableHydrationReminders") { enableHydrationReminders = true } // Default
        
        enableDrinkingDurationAlerts = UserDefaults.standard.bool(forKey: "enableDrinkingDurationAlerts")
        if !UserDefaults.standard.contains(key: "enableDrinkingDurationAlerts") { enableDrinkingDurationAlerts = true } // Default
        
        enableMorningCheckIns = UserDefaults.standard.bool(forKey: "enableMorningCheckIns")
        
        // Privacy settings
        enablePasscodeProtection = UserDefaults.standard.bool(forKey: "enablePasscodeProtection")
        useBiometricAuthentication = UserDefaults.standard.bool(forKey: "useBiometricAuthentication")
        allowDataSharing = UserDefaults.standard.bool(forKey: "allowDataSharing")
        
        // Display settings
        useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
        enableDarkMode = UserDefaults.standard.bool(forKey: "enableDarkMode")
        alwaysShowBAC = UserDefaults.standard.bool(forKey: "alwaysShowBAC")
        if !UserDefaults.standard.contains(key: "alwaysShowBAC") { alwaysShowBAC = true } // Default
        
        // Watch settings
        syncWithAppleWatch = UserDefaults.standard.bool(forKey: "syncWithAppleWatch")
        if !UserDefaults.standard.contains(key: "syncWithAppleWatch") { syncWithAppleWatch = true } // Default
        
        watchQuickAdd = UserDefaults.standard.bool(forKey: "watchQuickAdd")
        if !UserDefaults.standard.contains(key: "watchQuickAdd") { watchQuickAdd = true } // Default
        
        watchComplication = UserDefaults.standard.bool(forKey: "watchComplication")
        if !UserDefaults.standard.contains(key: "watchComplication") { watchComplication = true } // Default
    }
    
    func saveSettings() {
        // User profile
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(gender.rawValue.lowercased(), forKey: "userGender")
        UserDefaults.standard.set(heightFeet, forKey: "userHeightFeet")
        UserDefaults.standard.set(heightInches, forKey: "userHeightInches")
        
        // Tracking settings
        UserDefaults.standard.set(trackDrinkHistory, forKey: "trackDrinkHistory")
        UserDefaults.standard.set(trackLocations, forKey: "trackLocations")
        UserDefaults.standard.set(saveAlcoholSpending, forKey: "saveAlcoholSpending")
        UserDefaults.standard.set(saveDrinksFor, forKey: "saveDrinksFor")
        
        // Notification settings
        UserDefaults.standard.set(enableBACAlerts, forKey: "enableBACAlerts")
        UserDefaults.standard.set(enableHydrationReminders, forKey: "enableHydrationReminders")
        UserDefaults.standard.set(enableDrinkingDurationAlerts, forKey: "enableDrinkingDurationAlerts")
        UserDefaults.standard.set(enableMorningCheckIns, forKey: "enableMorningCheckIns")
        
        // Privacy settings
        UserDefaults.standard.set(enablePasscodeProtection, forKey: "enablePasscodeProtection")
        UserDefaults.standard.set(useBiometricAuthentication, forKey: "useBiometricAuthentication")
        UserDefaults.standard.set(allowDataSharing, forKey: "allowDataSharing")
        
        // Display settings
        UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits")
        UserDefaults.standard.set(enableDarkMode, forKey: "enableDarkMode")
        UserDefaults.standard.set(alwaysShowBAC, forKey: "alwaysShowBAC")
        
        // Watch settings
        UserDefaults.standard.set(syncWithAppleWatch, forKey: "syncWithAppleWatch")
        UserDefaults.standard.set(watchQuickAdd, forKey: "watchQuickAdd")
        UserDefaults.standard.set(watchComplication, forKey: "watchComplication")
    }
    
    func applyAppearanceSettings() {
        // Apply dark mode setting
        DispatchQueue.main.async {
            if #available(iOS 15.0, *) {
                let scenes = UIApplication.shared.connectedScenes
                scenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.overrideUserInterfaceStyle = self.enableDarkMode ? .dark : .light
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    
    func updateUserProfile(weight: Double, gender: Gender) {
        self.weight = weight
        self.gender = gender
        
        // Update drink tracker with new profile info
        let updatedUserProfile = UserProfile(
            weight: weight,
            gender: gender,
            emergencyContacts: []
        )
        
        DrinkTracker().updateUserProfile(updatedUserProfile)
    }
    
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
    
    // MARK: - Reset Settings
    
    func resetToDefaults() {
        // User profile
        weight = 160.0
        gender = .male
        heightFeet = 5
        heightInches = 10
        
        // Tracking settings
        trackDrinkHistory = true
        trackLocations = false
        saveAlcoholSpending = true
        saveDrinksFor = 90
        
        // Notification settings
        enableBACAlerts = true
        enableHydrationReminders = true
        enableDrinkingDurationAlerts = true
        enableMorningCheckIns = false
        
        // Privacy settings
        enablePasscodeProtection = false
        useBiometricAuthentication = false
        allowDataSharing = false
        
        // Display settings
        useMetricUnits = false
        enableDarkMode = false
        alwaysShowBAC = true
        
        // Watch settings
        syncWithAppleWatch = true
        watchQuickAdd = true
        watchComplication = true
        
        // Save all default settings
        saveSettings()
        
        // Apply dark mode setting
        applyAppearanceSettings()
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        // Clear all user data (but keep settings)
        
        // Clear drink history
        let drinkTracker = DrinkTracker()
        drinkTracker.clearDrinks()
        
        // Clear any saved shares
        UserDefaults.standard.removeObject(forKey: "activeShares")
        
        // Clear emergency contacts (but don't remove settings)
        let emergencyManager = EmergencyContactManager.shared
        emergencyManager.emergencyContacts = []
        emergencyManager.saveContacts()
        
        // Cancel all notifications
        NotificationManager.shared.cancelAllNotifications()
    }
    
    func exportUserData() -> Data? {
        // Create a dictionary with all user data
        var userData: [String: Any] = [:]
        
        // Get drinks data
        if let drinksData = UserDefaults.standard.data(forKey: "savedDrinks"),
           let drinks = try? JSONDecoder().decode([Drink].self, from: drinksData) {
            userData["drinks"] = drinks
        }
        
        // Get user profile
        if let profileData = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            userData["userProfile"] = profile
        }
        
        // Get emergency contacts
        if let contactsData = UserDefaults.standard.data(forKey: "emergencyContacts"),
           let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: contactsData) {
            userData["emergencyContacts"] = contacts
        }
        
        // Add all settings
        userData["settings"] = [
            "weight": weight,
            "gender": gender.rawValue,
            "heightFeet": heightFeet,
            "heightInches": heightInches,
            "trackDrinkHistory": trackDrinkHistory,
            "trackLocations": trackLocations,
            "saveAlcoholSpending": saveAlcoholSpending,
            "saveDrinksFor": saveDrinksFor,
            "enableBACAlerts": enableBACAlerts,
            "enableHydrationReminders": enableHydrationReminders,
            "enableDrinkingDurationAlerts": enableDrinkingDurationAlerts,
            "enableMorningCheckIns": enableMorningCheckIns,
            "useMetricUnits": useMetricUnits,
            "enableDarkMode": enableDarkMode,
            "alwaysShowBAC": alwaysShowBAC
        ]
        
        // Serialize the data to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Error serializing user data: \(error)")
            return nil
        }
    }
    
    func importUserData(from jsonData: Data) -> Bool {
        do {
            // Parse the JSON data
            if let userData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                
                // Import drinks if available
                if let drinksArray = userData["drinks"] as? [[String: Any]] {
                    if let drinksData = try? JSONSerialization.data(withJSONObject: drinksArray, options: []),
                       let _ = try? JSONDecoder().decode([Drink].self, from: drinksData) {
                        // Save the imported drinks
                        UserDefaults.standard.set(drinksData, forKey: "savedDrinks")
                    }
                }
                
                // Import user profile if available
                if let profileDict = userData["userProfile"] as? [String: Any] {
                    if let profileData = try? JSONSerialization.data(withJSONObject: profileDict, options: []),
                       let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
                        // Save the imported profile
                        UserDefaults.standard.set(profileData, forKey: "userProfile")
                        
                        // Update current settings
                        weight = profile.weight
                        gender = profile.gender
                    }
                }
                
                // Import emergency contacts if available
                if let contactsArray = userData["emergencyContacts"] as? [[String: Any]] {
                    if let contactsData = try? JSONSerialization.data(withJSONObject: contactsArray, options: []),
                       let contacts = try? JSONDecoder().decode([EmergencyContact].self, from: contactsData) {
                        // Save the imported contacts
                        UserDefaults.standard.set(contactsData, forKey: "emergencyContacts")
                        
                        // Update emergency contacts manager
                        EmergencyContactManager.shared.emergencyContacts = contacts
                    }
                }
                
                // Import settings if available
                if let settings = userData["settings"] as? [String: Any] {
                    // Import each setting, with fallback to current value
                    weight = settings["weight"] as? Double ?? weight
                    if let genderString = settings["gender"] as? String {
                        gender = genderString.lowercased() == "male" ? .male : .female
                    }
                    heightFeet = settings["heightFeet"] as? Int ?? heightFeet
                    heightInches = settings["heightInches"] as? Int ?? heightInches
                    
                    trackDrinkHistory = settings["trackDrinkHistory"] as? Bool ?? trackDrinkHistory
                    trackLocations = settings["trackLocations"] as? Bool ?? trackLocations
                    saveAlcoholSpending = settings["saveAlcoholSpending"] as? Bool ?? saveAlcoholSpending
                    saveDrinksFor = settings["saveDrinksFor"] as? Int ?? saveDrinksFor
                    
                    enableBACAlerts = settings["enableBACAlerts"] as? Bool ?? enableBACAlerts
                    enableHydrationReminders = settings["enableHydrationReminders"] as? Bool ?? enableHydrationReminders
                    enableDrinkingDurationAlerts = settings["enableDrinkingDurationAlerts"] as? Bool ?? enableDrinkingDurationAlerts
                    enableMorningCheckIns = settings["enableMorningCheckIns"] as? Bool ?? enableMorningCheckIns
                    
                    useMetricUnits = settings["useMetricUnits"] as? Bool ?? useMetricUnits
                    enableDarkMode = settings["enableDarkMode"] as? Bool ?? enableDarkMode
                    alwaysShowBAC = settings["alwaysShowBAC"] as? Bool ?? alwaysShowBAC
                    
                    // Save all imported settings
                    saveSettings()
                    
                    // Apply appearance settings
                    applyAppearanceSettings()
                }
                
                return true
            }
        } catch {
            print("Error importing user data: \(error)")
            return false
        }
        
        return false
    }
}
