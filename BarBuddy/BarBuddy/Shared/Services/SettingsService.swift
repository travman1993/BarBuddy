import Foundation
import SwiftUI

class SettingsService {
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
    }
    
    // Get current app settings
    func getSettings() async throws -> Settings {
        return try await storageService.getSettings()
    }
    
    // Save app settings
    func saveSettings(_ settings: Settings) async throws {
        try await storageService.saveSettings(settings)
    }
    
    // Update specific settings
    func updateSettings(
        useDarkMode: Bool? = nil,
        useMetricUnits: Bool? = nil,
        enableSafetyAlerts: Bool? = nil,
        enableCheckInReminders: Bool? = nil,
        enableBACUpdates: Bool? = nil,
        enableHydrationReminders: Bool? = nil,
        saveLocationData: Bool? = nil,
        analyticsEnabled: Bool? = nil,
        showBAConHomeScreen: Bool? = nil,
        showEmergencyButtonOnHomeScreen: Bool? = nil,
        enableWatchAppNotifications: Bool? = nil,
        showComplicationOnWatchFace: Bool? = nil
    ) async throws -> Settings {
        var settings = try await getSettings()
        
        if let useDarkMode = useDarkMode {
            settings.useDarkMode = useDarkMode
        }
        
        if let useMetricUnits = useMetricUnits {
            settings.useMetricUnits = useMetricUnits
        }
        
        if let enableSafetyAlerts = enableSafetyAlerts {
            settings.enableSafetyAlerts = enableSafetyAlerts
        }
        
        if let enableCheckInReminders = enableCheckInReminders {
            settings.enableCheckInReminders = enableCheckInReminders
        }
        
        if let enableBACUpdates = enableBACUpdates {
            settings.enableBACUpdates = enableBACUpdates
        }
        
        if let enableHydrationReminders = enableHydrationReminders {
            settings.enableHydrationReminders = enableHydrationReminders
        }
        
        if let saveLocationData = saveLocationData {
            settings.saveLocationData = saveLocationData
        }
        
        if let analyticsEnabled = analyticsEnabled {
            settings.analyticsEnabled = analyticsEnabled
        }
        
        if let showBAConHomeScreen = showBAConHomeScreen {
            settings.showBAConHomeScreen = showBAConHomeScreen
        }
        
        if let showEmergencyButtonOnHomeScreen = showEmergencyButtonOnHomeScreen {
            settings.showEmergencyButtonOnHomeScreen = showEmergencyButtonOnHomeScreen
        }
        
        if let enableWatchAppNotifications = enableWatchAppNotifications {
            settings.enableWatchAppNotifications = enableWatchAppNotifications
        }
        
        if let showComplicationOnWatchFace = showComplicationOnWatchFace {
            settings.showComplicationOnWatchFace = showComplicationOnWatchFace
        }
        
        try await saveSettings(settings)
        return settings
    }
    
    // Toggle dark mode
    func toggleDarkMode() async throws -> Bool {
        var settings = try await getSettings()
        settings.useDarkMode = !settings.useDarkMode
        try await saveSettings(settings)
        return settings.useDarkMode
    }
    
    // Toggle metric units
    func toggleMetricUnits() async throws -> Bool {
        var settings = try await getSettings()
        settings.useMetricUnits = !settings.useMetricUnits
        try await saveSettings(settings)
        return settings.useMetricUnits
    }
    
    // Reset settings to defaults
    func resetToDefaults() async throws -> Settings {
        let defaultSettings = Settings.default
        try await saveSettings(defaultSettings)
        return defaultSettings
    }
    
    // Convert weight between units
    func convertWeight(_ weight: Double, toMetric: Bool = false) -> Double {
        if toMetric {
            // Convert lbs to kg
            return weight * 0.453592
        } else {
            // Convert kg to lbs
            return weight * 2.20462
        }
    }
    
    // Get appropriate weight unit string
    func weightUnit(isMetric: Bool) -> String {
        return isMetric ? "kg" : "lbs"
    }
    
    // Get appropriate volume unit string
    func volumeUnit(isMetric: Bool) -> String {
        return isMetric ? "ml" : "oz"
    }
    
    // Convert volume between units
    func convertVolume(_ volume: Double, toMetric: Bool = false) -> Double {
        if toMetric {
            // Convert oz to ml
            return volume * 29.5735
        } else {
            // Convert ml to oz
            return volume * 0.033814
        }
    }
}
