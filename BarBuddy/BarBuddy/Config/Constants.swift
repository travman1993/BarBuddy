//
//  Constants.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import SwiftUI

struct Constants {
    // App info
    struct App {
        static let name = "BarBuddy"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleId = Bundle.main.bundleIdentifier ?? "com.example.barbuddy"
        static let appStoreURL = "https://apps.apple.com/app/barbuddy/id0000000000"
        static let websiteURL = "https://barbuddy.app"
        static let supportEmail = "support@barbuddy.app"
        static let privacyPolicyURL = "https://barbuddy.app/privacy"
        static let termsOfServiceURL = "https://barbuddy.app/terms"
    }
    
    // BAC related constants
    struct BAC {
        static let legalLimit: Double = 0.08 // Legal BAC limit in most US states
        static let cautionThreshold: Double = 0.05 // Start showing caution at this BAC
        static let highThreshold: Double = 0.15 // High intoxication level
        static let metabolismRate: Double = 0.015 // Average decrease in BAC per hour
        static let standardDrinkAlcoholGrams: Double = 14.0 // Grams of pure alcohol in a standard drink
    }
    
    // Time constants
    struct Time {
        static let secondsInMinute = 60
        static let minutesInHour = 60
        static let hoursInDay = 24
        static let secondsInHour = secondsInMinute * minutesInHour
        static let secondsInDay = secondsInHour * hoursInDay
        static let checkInReminderMinutes = 30 // Minutes after drinking to send check-in reminder
        static let inactivityCheckInHours = 2 // Hours of inactivity before check-in prompt
        static let hydrationReminderMinutes = 60 // Minutes between hydration reminders
    }
    
    // UI constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let buttonHeight: CGFloat = 54
        static let iconSize: CGFloat = 24
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let animationDuration: Double = 0.3
        static let maxContentWidth: CGFloat = 500 // For iPad/larger screens
    }
    
    // Strings used throughout the app
    struct Strings {
        static let disclaimerText = """
        DISCLAIMER: BarBuddy provides BAC estimates for informational purposes only. Many factors can affect individual BAC levels, and the app should not be used as a definitive guide for determining whether you are legally fit to drive.

        The only truly safe amount of alcohol to consume before driving is zero. Always err on the side of caution and arrange alternative transportation if you have been drinking.

        By using this app, you acknowledge these limitations and agree that the developers accept no responsibility for any decisions made based on information provided by the app.
        """
        
        static let emergencyButtonText = "EMERGENCY CONTACT"
        static let rideShareButtonText = "GET A RIDE"
        static let addDrinkButtonText = "ADD DRINK"
        static let checkInButtonText = "CHECK IN"
        
        // Tab labels
        static let homeTabLabel = "Home"
        static let historyTabLabel = "History"
        static let settingsTabLabel = "Settings"
        
        // Error messages
        static let genericErrorMessage = "Something went wrong. Please try again."
        static let networkErrorMessage = "Network error. Please check your connection."
        static let locationPermissionDeniedMessage = "Location permission denied. Some features will be limited."
    }
    
    // Notification categories
    struct NotificationCategories {
        static let bacUpdate = "BAC_UPDATE"
        static let emergency = "EMERGENCY"
        static let checkIn = "CHECK_IN"
        static let hydration = "HYDRATION"
    }
    
    // UserDefaults keys
    struct UserDefaultsKeys {
        static let currentUserId = "currentUserId"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let hasAcceptedDisclaimer = "hasAcceptedDisclaimer"
        static let appSettings = "appSettings"
        static let lastActiveDate = "lastActiveDate"
        static let lastLaunchDate = "lastLaunchDate"
        static let launchCount = "launchCount"
    }
    
    // Device detection
    struct Device {
        static var isPhone: Bool {
            return UIDevice.current.userInterfaceIdiom == .phone
        }
        
        static var isPad: Bool {
            return UIDevice.current.userInterfaceIdiom == .pad
        }
        
        static var isWatch: Bool {
            #if os(watchOS)
            return true
            #else
            return false
            #endif
        }
        
        // Detect if running on simulator
        static var isSimulator: Bool {
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
        }
    }
    
    // Environment detection
    struct Environment {
        #if DEBUG
        static let isDebug = true
        #else
        static let isDebug = false
        #endif
        
        // Determine if this is a TestFlight build
        static var isTestFlight: Bool {
            guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
            return receiptURL.path.contains("sandboxReceipt")
        }
    }
}
