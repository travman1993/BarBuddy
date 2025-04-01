//
//  NotificationManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // Singleton instance
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published var isNotificationsEnabled = false
    
    // MARK: - Notification Settings
    @Published var sendBACAlerts = true
    @Published var sendHydrationReminders = true
    @Published var sendDrinkingDurationAlerts = true
    @Published var sendAfterPartyReminders = true
    
    // MARK: - Notification Categories
    private enum NotificationCategory: String {
        case bacAlert = "BAC_ALERT"
        case hydrationReminder = "HYDRATION_REMINDER"
        case drinkingDuration = "DURATION_ALERT"
        case afterPartyCheckIn = "AFTER_PARTY_REMINDER"
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationStatus()
    }
    
    // MARK: - Permission Management
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
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
    
    // MARK: - Notification Categories Setup
    private func setupNotificationCategories() {
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
        
        // BAC Alert Category
        let bacCategory = UNNotificationCategory(
            identifier: NotificationCategory.bacAlert.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Hydration Reminder Category
        let hydrationCategory = UNNotificationCategory(
            identifier: NotificationCategory.hydrationReminder.rawValue,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Drinking Duration Alert Category
        let durationCategory = UNNotificationCategory(
            identifier: NotificationCategory.drinkingDuration.rawValue,
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // After Party Check-in Category
        let afterPartyCategory = UNNotificationCategory(
            identifier: NotificationCategory.afterPartyCheckIn.rawValue,
            actions: [
                UNNotificationAction(
                    identifier: "FEELING_GOOD",
                    title: "Feeling Good",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "NEED_HELP",
                    title: "Need Help",
                    options: .foreground
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            bacCategory,
            hydrationCategory,
            durationCategory,
            afterPartyCategory
        ])
    }
    
    // MARK: - BAC Notifications
    func scheduleBACNotification(bac: Double) {
        guard isNotificationsEnabled && sendBACAlerts else { return }
        
        // Clear existing BAC notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["bac-alert"]
        )
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["bac-alert"]
        )
        
        // High BAC alert
        if bac >= 0.08 {
            let content = createBACAlertContent(
                title: "High BAC Alert",
                body: "Your estimated BAC is \(String(format: "%.3f", bac)), which is over the legal limit for driving. Please arrange for a safe ride home.",
                category: .bacAlert
            )
            
            scheduleImmediateNotification(
                identifier: "bac-alert",
                content: content
            )
        }
        // Moderate BAC alert
        else if bac >= 0.05 {
            let content = createBACAlertContent(
                title: "BAC Alert",
                body: "Your estimated BAC is \(String(format: "%.3f", bac)). Consider slowing down your drinking.",
                category: .bacAlert
            )
            
            scheduleImmediateNotification(
                identifier: "bac-alert",
                content: content
            )
        }
    }
    
    // MARK: - Hydration Reminders
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
    
    // MARK: - Drinking Duration Alerts
    func scheduleDrinkingDurationAlert(startTime: Date) {
        guard isNotificationsEnabled && sendDrinkingDurationAlerts else { return }
        
        // 3-hour alert
        scheduleTimeBasedAlert(
            timeFrom: startTime,
            hours: 3,
            title: "Drinking Duration Alert",
            body: "You've been drinking for about 3 hours. Consider slowing down or switching to water.",
            category: .drinkingDuration
        )
        
        // 5-hour alert
        scheduleTimeBasedAlert(
            timeFrom: startTime,
            hours: 5,
            title: "Extended Drinking Alert",
            body: "You've been drinking for about 5 hours. Consider taking a break and getting a safe ride home.",
            category: .drinkingDuration
        )
    }
    
    // MARK: - After Party Check-in
    func scheduleAfterPartyReminder(forHoursLater hours: Int = 8) {
        guard isNotificationsEnabled && sendAfterPartyReminders else { return }
        
        let content = createNotificationContent(
            title: "Morning Check-in",
            body: "How are you feeling after last night's drinking? Tap to log your recovery.",
            category: .afterPartyCheckIn
        )
        
        scheduleDelayedNotification(
            identifier: "after-party",
            content: content,
            timeInterval: TimeInterval(hours * 3600)
        )
    }
    
    // MARK: - Notification Creation Helpers
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
    
    private func createBACAlertContent(
        title: String,
        body: String,
        category: NotificationCategory
    ) -> UNMutableNotificationContent {
        let content = createNotificationContent(
            title: title,
            body: body,
            category: category
        )
        content.sound = .default
        return content
    }
    
    // MARK: - Notification Scheduling Helpers
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
    
    private func scheduleTimeBasedAlert(
        timeFrom startTime: Date,
        hours: Int,
        title: String,
        body: String,
        category: NotificationCategory
    ) {
        let laterTime = startTime.addingTimeInterval(Double(hours) * 3600)
        
        // Only schedule if the alert time is in the future
        guard laterTime > Date() else { return }
        
        let timeUntilAlert = laterTime.timeIntervalSince(Date())
        
        let content = createNotificationContent(
            title: title,
            body: body,
            category: category
        )
        
        scheduleDelayedNotification(
            identifier: "duration-\(hours)hr",
            content: content,
            timeInterval: timeUntilAlert
        )
    }
    
    // MARK: - Notification Management
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotificationsWithPrefix(_ prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request in
                request.identifier.hasPrefix(prefix) ? request.identifier : nil
            }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: identifiersToRemove
            )
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications.compactMap { notification in
                notification.request.identifier.hasPrefix(prefix) ? notification.request.identifier : nil
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: identifiersToRemove
            )
        }
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
        case "FEELING_GOOD", "NEED_HELP":
            // These would be handled in the app's UI
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Utility Methods
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
