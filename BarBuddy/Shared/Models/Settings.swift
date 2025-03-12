import Foundation

struct Settings: Codable, Equatable {
    // Appearance settings
    var useDarkMode: Bool = false
    var useMetricUnits: Bool = false
    
    // Notification settings
    var enableSafetyAlerts: Bool = true
    var enableCheckInReminders: Bool = true
    var enableBACUpdates: Bool = true
    var enableHydrationReminders: Bool = true
    
    // Privacy settings
    var saveLocationData: Bool = true
    var analyticsEnabled: Bool = true
    
    // Display settings
    var showBAConHomeScreen: Bool = true
    var showEmergencyButtonOnHomeScreen: Bool = true
    
    // Watch app settings
    var enableWatchAppNotifications: Bool = true
    var showComplicationOnWatchFace: Bool = true
    
    // Default settings
    static let `default` = Settings()
}
