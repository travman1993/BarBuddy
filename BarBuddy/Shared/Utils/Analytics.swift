import Foundation

enum AnalyticsEvent: String {
    case appOpened = "app_opened"
    case userSignedIn = "user_signed_in"
    case userSignedOut = "user_signed_out"
    case drinkAdded = "drink_added"
    case drinkDeleted = "drink_deleted"
    case contactAdded = "contact_added"
    case contactDeleted = "contact_deleted"
    case emergencyAlertSent = "emergency_alert_sent"
    case checkInSent = "check_in_sent"
    case bagLegalLimit = "bac_legal_limit"
    case bacHigh = "bac_high"
    case settingsChanged = "settings_changed"
    case disclaimerAccepted = "disclaimer_accepted"
}

class Analytics {
    static let shared = Analytics()
    
    private var enabled = true
    
    private init() {
        // In a real app, this would initialize the analytics SDK
    }
    
    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }
    
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        guard enabled else { return }
        
        // In a real app, this would log to Firebase, Amplitude, etc.
        print("📊 Analytics: \(event.rawValue), parameters: \(parameters)")
    }
    
    func logError(_ error: Error, context: String) {
        guard enabled else { return }
        
        // In a real app, this would log to Crashlytics, etc.
        print("⚠️ Error: \(error.localizedDescription), context: \(context)")
    }
    
    func logScreen(_ screenName: String) {
        guard enabled else { return }
        
        // In a real app, this would log screen views
        print("📱 Screen view: \(screenName)")
    }
    
    func logDrinkAdded(type: DrinkType, standardDrinks: Double) {
        logEvent(.drinkAdded, parameters: [
            "type": type.rawValue,
            "standard_drinks": standardDrinks
        ])
    }
    
    func logBACUpdate(bac: Double, isAboveLegalLimit: Bool) {
        logEvent(.bagLegalLimit, parameters: [
            "bac": bac,
            "above_legal_limit": isAboveLegalLimit
        ])
        
        if bac >= Constants.BAC.highThreshold {
            logEvent(.bacHigh, parameters: ["bac": bac])
        }
    }
}
