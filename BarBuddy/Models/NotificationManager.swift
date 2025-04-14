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
        case drinkingLimit = "DRINKING_LIMIT"
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
        
        let drinkLimitCategory = UNNotificationCategory(
            identifier: NotificationCategory.drinkingLimit.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        
        // Create notification category
        let bacCategory = UNNotificationCategory(
            identifier: NotificationCategory.bacAlert.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Create hydration reminder category
        let hydrationCategory = UNNotificationCategory(
            identifier: NotificationCategory.hydrationReminder.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Create drinking duration alert category
        let durationCategory = UNNotificationCategory(
            identifier: NotificationCategory.drinkingDuration.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Create after party check-in category
        let afterPartyCategory = UNNotificationCategory(
            identifier: NotificationCategory.afterPartyCheckIn.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            bacCategory, // keep this for backwards compatibility
            hydrationCategory,
            durationCategory,
            afterPartyCategory,
            drinkLimitCategory // add this new category
        ])
    }
    
    /**
     * Schedules a notification based on the user's current drink count versus limit.
     */
    func scheduleDrinkLimitNotification(currentCount: Double, limit: Double) {
        guard isNotificationsEnabled && sendBACAlerts else { return }
        
        // Clear existing drink limit notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["drink-limit-alert"]
        )
        
        // Create and schedule appropriate notification based on drink count
        if currentCount >= limit {
            let content = createNotificationContent(
                title: "Drink Limit Reached",
                body: "You've reached your drink limit of \(Int(limit)) standard drinks. Consider switching to water.",
                category: .bacAlert // Reusing the existing category
            )
            
            scheduleImmediateNotification(
                identifier: "drink-limit-alert",
                content: content
            )
        }
        else if currentCount >= limit * 0.75 {
            // Schedule approaching limit alert
            let content = createNotificationContent(
                title: "Approaching Drink Limit",
                body: "You're approaching your drink limit of \(Int(limit)) standard drinks. Consider slowing down.",
                category: .bacAlert // Reusing the existing category
            )
            
            scheduleImmediateNotification(
                identifier: "drink-limit-alert",
                content: content
            )
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
    /**
     * Schedules notifications to monitor drinking duration.
     * Alerts the user when they've been drinking for an extended period.
     */
    func scheduleDrinkingDurationAlert(startTime: Date) {
        guard isNotificationsEnabled && sendDrinkingDurationAlerts else { return }
        
        // Schedule alert for 3 hours after drinking started
        let threeHourContent = createNotificationContent(
            title: "Drinking Duration Alert",
            body: "You've been drinking for 3 hours. Consider taking a break or switching to water.",
            category: .drinkingDuration
        )
        
        scheduleDelayedNotification(
            identifier: "duration-3hr",
            content: threeHourContent,
            timeInterval: 3 * 60 * 60
        )
        
        // Schedule another alert for 5 hours after drinking started
        let fiveHourContent = createNotificationContent(
            title: "Extended Drinking Alert",
            body: "You've been drinking for 5 hours. Consider ending your session or getting a ride home.",
            category: .drinkingDuration
        )
        
        scheduleDelayedNotification(
            identifier: "duration-5hr",
            content: fiveHourContent,
            timeInterval: 5 * 60 * 60
        )
    }
    
    /**
     * Schedules a morning check-in notification for the next day.
     * Useful for checking on the user after a night of drinking.
     */
    func scheduleAfterPartyReminder() {
        guard isNotificationsEnabled && sendAfterPartyReminders else { return }
        
        let content = createNotificationContent(
            title: "Morning Check-In",
            body: "Good morning! How are you feeling today? Remember to hydrate and rest if needed.",
            category: .afterPartyCheckIn
        )
        
        // Calculate time for next morning (10 AM)
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.day! += 1 // Next day
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        if let nextMorning = calendar.date(from: dateComponents) {
            scheduleCalendarNotification(
                identifier: "morning-checkin",
                content: content,
                date: nextMorning
            )
        }
    }
    
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
    
    /**
     * Schedules a notification to be delivered at a specific date.
     */
    private func scheduleCalendarNotification(
        identifier: String,
        content: UNMutableNotificationContent,
        date: Date
    ) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
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
