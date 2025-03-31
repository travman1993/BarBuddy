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
    static let shared = NotificationManager()
    
    @Published var isNotificationsEnabled = false
    
    // User settings for notifications
    @Published var sendBACAlerts = true
    @Published var sendHydrationReminders = true
    @Published var sendDrinkingDurationAlerts = true
    @Published var sendAfterPartyReminders = true
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkNotificationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
                self.setupNotificationCategories()
                completion(granted)
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Create actions for BAC notifications
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
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )
        
        // BAC Alert Category
        let bacCategory = UNNotificationCategory(
            identifier: "BAC_ALERT",
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Hydration Reminder Category
        let hydrationCategory = UNNotificationCategory(
            identifier: "HYDRATION_REMINDER",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Drinking Duration Alert Category
        let durationCategory = UNNotificationCategory(
            identifier: "DURATION_ALERT",
            actions: [getUberAction, getLyftAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // After Party Check-in Category
        let afterPartyCategory = UNNotificationCategory(
            identifier: "AFTER_PARTY_REMINDER",
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
        
        // Register the notification categories
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
        
        // Clear any existing BAC notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["bac-alert"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bac-alert"])
        
        if bac >= 0.08 {
            // Schedule immediate notification for high BAC
            let content = UNMutableNotificationContent()
            content.title = "High BAC Alert"
            content.body = "Your estimated BAC is \(String(format: "%.3f", bac)), which is over the legal limit for driving. Please arrange for a safe ride home."
            content.sound = .default
            content.categoryIdentifier = "BAC_ALERT"
            
            let request = UNNotificationRequest(
                identifier: "bac-alert",
                content: content,
                trigger: nil  // Deliver immediately
            )
            
            UNUserNotificationCenter.current().add(request)
        } else if bac >= 0.05 {
            // Schedule notification for moderate BAC
            let content = UNMutableNotificationContent()
            content.title = "BAC Alert"
            content.body = "Your estimated BAC is \(String(format: "%.3f", bac)). Consider slowing down your drinking."
            content.sound = .default
            content.categoryIdentifier = "BAC_ALERT"
            
            let request = UNNotificationRequest(
                identifier: "bac-alert",
                content: content,
                trigger: nil  // Deliver immediately
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - Hydration Reminders
    
    func scheduleHydrationReminder(afterMinutes: Int = 30) {
        guard isNotificationsEnabled && sendHydrationReminders else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Hydration Reminder"
        content.body = "Remember to drink water between alcoholic drinks to stay hydrated."
        content.sound = .default
        content.categoryIdentifier = "HYDRATION_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(afterMinutes * 60),
            repeats: false
        )
        
        let identifier = "hydration-\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Drinking Duration Alerts
    
    func scheduleDrinkingDurationAlert(startTime: Date) {
        guard isNotificationsEnabled && sendDrinkingDurationAlerts else { return }
        
        // Schedule alert for 3 hours of drinking
        let threeHoursLater = startTime.addingTimeInterval(3 * 3600)
        if threeHoursLater > Date() {
            let timeUntilAlert = threeHoursLater.timeIntervalSince(Date())
            
            let content = UNMutableNotificationContent()
            content.title = "Drinking Duration Alert"
            content.body = "You've been drinking for about 3 hours. Consider slowing down or switching to water."
            content.sound = .default
            content.categoryIdentifier = "DURATION_ALERT"
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeUntilAlert,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "duration-3hr",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
        
        // Schedule alert for 5 hours of drinking
        let fiveHoursLater = startTime.addingTimeInterval(5 * 3600)
        if fiveHoursLater > Date() {
            let timeUntilAlert = fiveHoursLater.timeIntervalSince(Date())
            
            let content = UNMutableNotificationContent()
            content.title = "Extended Drinking Alert"
            content.body = "You've been drinking for about 5 hours. Consider taking a break and getting a safe ride home."
            content.sound = .default
            content.categoryIdentifier = "DURATION_ALERT"
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeUntilAlert,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "duration-5hr",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // MARK: - After Party Check-in
    
    func scheduleAfterPartyReminder(forHoursLater hours: Int = 8) {
        guard isNotificationsEnabled && sendAfterPartyReminders else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Morning Check-in"
        content.body = "How are you feeling after last night's drinking? Tap to log your recovery."
        content.sound = .default
        content.categoryIdentifier = "AFTER_PARTY_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "after-party",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotificationsWithPrefix(_ prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.compactMap { request in
                request.identifier.hasPrefix(prefix) ? request.identifier : nil
            }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications.compactMap { notification in
                notification.request.identifier.hasPrefix(prefix) ? notification.request.identifier : nil
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification action
        let identifier = response.actionIdentifier
        _ = response.notification
        
        switch identifier {
        case "GET_UBER":
            openRideShareApp(appUrlScheme: "uber://")
        case "GET_LYFT":
            openRideShareApp(appUrlScheme: "lyft://")
        case "FEELING_GOOD", "NEED_HELP":
            // These would be handled in the app's UI
            // by showing the appropriate follow-up screens
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    private func openRideShareApp(appUrlScheme: String) {
        if let url = URL(string: appUrlScheme) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let webUrl = URL(string: appUrlScheme == "uber://" ? "https://m.uber.com" : "https://www.lyft.com") {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}
