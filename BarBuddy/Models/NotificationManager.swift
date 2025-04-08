//
//  NotificationManager.swift
//  BarBuddy
//

import Foundation
import UserNotifications
import SwiftUI

/**
 * Manages all notification-related functionality in the app.
 *
 * This class handles requesting permissions, scheduling various types of notifications,
 * and responding to user interactions with notifications.
 */
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// Shared singleton instance
    static let shared = NotificationManager()
    
    /// Indicates if the user has granted notification permissions
    @Published var isNotificationsEnabled = false
    
    /// Controls whether different types of notifications should be sent
    @Published var sendBACAlerts = true
    @Published var sendHydrationReminders = true
    @Published var sendDrinkingDurationAlerts = true
    @Published var sendAfterPartyReminders = true
    
    /**
     * Categories of notifications used in the app.
     */
    private enum NotificationCategory: String {
        case bacAlert = "BAC_ALERT"
        case hydrationReminder = "HYDRATION_REMINDER"
        case drinkingDuration = "DURATION_ALERT"
        case afterPartyCheckIn = "AFTER_PARTY_REMINDER"
    }
    
    /**
     * Private initializer to enforce singleton pattern.
     */
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationStatus()
    }
    
    /**
     * Checks the current notification permission status.
     */
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /**
     * Requests permission to send notifications to the user.
     */
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
                if granted {
                    self.setupNotificationCategories()
                }
                completion(granted)
            }
        }
    }
    
    /**
     * Sets up notification categories with associated actions.
     */
    func setupNotificationCategories() {
        // Rideshare actions
        let getUberAction = UNNotificationAction(
            identifier: "GET_UBER",
            title: "Get Uber",
            options: .foreground
        )
        
        let getLyftAction = UNNotificationAction(
            identifier: "GET_LYFT",
            title: "Get Lyft",
            options: .foreground
        )
        
        // Dismissal action
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        
        // Create various notification categories with appropriate actions
        let bacCategory = UNNotificationCategory(
            identifier: NotificationCategory.bacAlert.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Add other categories...
        
        // Register all categories
        UNUserNotificationCenter.current().setNotificationCategories([
            bacCategory
            // Include other categories here
        ])
    }
    
    /**
     * Schedules a notification based on the user's current BAC level.
     */
    func scheduleBACNotification(bac: Double) {
        guard isNotificationsEnabled && sendBACAlerts else { return }
        
        // Clear existing BAC notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["bac-alert"]
        )
        
        // Create and schedule appropriate notification based on BAC level
        if bac >= 0.08 {
            let content = createNotificationContent(
                title: "High BAC Alert",
                body: "Your estimated BAC is \(String(format: "%.3f", bac)), which is over the legal limit for driving.",
                category: .bacAlert
            )
            
            scheduleImmediateNotification(
                identifier: "bac-alert",
                content: content
            )
        }
        else if bac >= 0.05 {
            // Schedule moderate BAC alert
        }
    }
    
    /**
     * Schedules a reminder to drink water between alcoholic beverages.
     */
    func scheduleHydrationReminder(afterMinutes: Int = 30) {
        guard isNotificationsEnabled && sendHydrationReminders else { return }
        
        let content = createNotificationContent(
            title: "Hydration Reminder",
            body: "Remember to drink water between alcoholic drinks to stay hydrated.",
            category: .hydrationReminder
        )
        
        scheduleDelayedNotification(
            identifier: "hydration-\(UUID().uuidString)",
            content: content,
            timeInterval: TimeInterval(afterMinutes * 60)
        )
    }
    
    // Additional notification scheduling methods...
    
    /**
     * Creates a notification content object with the specified parameters.
     */
    private func createNotificationContent(
        title: String,
        body: String,
        category: NotificationCategory
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        return content
    }
    
    /**
     * Schedules an immediate notification.
     */
    private func scheduleImmediateNotification(
        identifier: String,
        content: UNMutableNotificationContent
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /**
     * Schedules a notification to be delivered after a delay.
     */
    private func scheduleDelayedNotification(
        identifier: String,
        content: UNMutableNotificationContent,
        timeInterval: TimeInterval
    ) {
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notifications when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification actions
        let identifier = response.actionIdentifier
        
        switch identifier {
        case "GET_UBER":
            openRideShareApp(appUrlScheme: "uber://")
        case "GET_LYFT":
            openRideShareApp(appUrlScheme: "lyft://")
        default:
            break
        }
        
        completionHandler()
    }
    
    /**
     * Opens a rideshare app to help the user get home safely.
     */
    private func openRideShareApp(appUrlScheme: String) {
        guard let url = URL(string: appUrlScheme) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web URL
            let webUrlString = appUrlScheme == "uber://"
                ? "https://m.uber.com"
                : "https://www.lyft.com"
            
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}
