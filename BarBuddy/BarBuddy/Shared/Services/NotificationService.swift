
import Foundation
import UserNotifications

class NotificationService {
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Request notification permissions
    func requestPermissions() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await notificationCenter.requestAuthorization(options: options)
        } catch {
            print("Error requesting notification permissions: \(error)")
            return false
        }
    }
    
    // Show immediate notification
    func showNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        categoryIdentifier: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    // Schedule notification for future time
    func scheduleNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String = UUID().uuidString,
        categoryIdentifier: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Cancel specific notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    // Cancel all notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - App-specific notifications
    
    // Set up notification categories and actions
    func setUpNotificationCategories() {
        // Emergency check-in category
        let checkInAction = UNNotificationAction(
            identifier: "CHECK_IN_ACTION",
            title: "I'm OK",
            options: .foreground
        )
        
        let callAction = UNNotificationAction(
            identifier: "CALL_ACTION",
            title: "Call Emergency Contact",
            options: .foreground
        )
        
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY_CATEGORY",
            actions: [checkInAction, callAction],
            intentIdentifiers: [],
            options: []
        )
        
        // BAC update category
        let viewBACAction = UNNotificationAction(
            identifier: "VIEW_BAC_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let getRideAction = UNNotificationAction(
            identifier: "GET_RIDE_ACTION",
            title: "Get a Ride",
            options: .foreground
        )
        
        let bacCategory = UNNotificationCategory(
            identifier: "BAC_CATEGORY",
            actions: [viewBACAction, getRideAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([emergencyCategory, bacCategory])
    }
    
    // Schedule BAC update notifications
        func scheduleBACSoberNotification(estimate: BACEstimate) {
            if estimate.bac <= 0 {
                return
            }
            
            // Notification for when BAC reaches legal limit (if applicable)
            if estimate.bac > Constants.BAC.legalLimit {
                scheduleNotification(
                    title: "BAC Update",
                    body: "Your BAC is now below the legal driving limit. Remember that impairment can occur at any BAC level.",
                    date: estimate.legalTime,
                    identifier: "bac_legal_limit",
                    categoryIdentifier: "BAC_CATEGORY"
                )
            }
            
            // Notification for when BAC reaches zero
            scheduleNotification(
                title: "BAC Update",
                body: "Your estimated BAC has returned to zero.",
                date: estimate.soberTime,
                identifier: "bac_zero",
                categoryIdentifier: "BAC_CATEGORY"
            )
        }
        
        // Show safety alert based on BAC level
        func showSafetyAlert(estimate: BACEstimate) {
            if estimate.bac >= Constants.BAC.highThreshold {
                showNotification(
                    title: "High BAC Alert",
                    body: "Your BAC is at a high level. DO NOT drive. Please stay hydrated and consider getting assistance if you feel unwell.",
                    identifier: "high_bac_alert",
                    categoryIdentifier: "BAC_CATEGORY"
                )
            } else if estimate.bac >= Constants.BAC.legalLimit {
                showNotification(
                    title: "BAC Above Legal Limit",
                    body: "Your BAC is above the legal driving limit. DO NOT drive. Consider using a ride-sharing service or calling a friend.",
                    identifier: "legal_limit_alert",
                    categoryIdentifier: "BAC_CATEGORY"
                )
            }
        }
        
        // Schedule check-in reminder
        func scheduleCheckInReminder(drinkTime: Date) {
            let reminderTime = drinkTime.addingTimeInterval(Double(Constants.Time.checkInReminderMinutes * 60))
            
            // Only schedule if reminder time is in the future
            if reminderTime > Date() {
                scheduleNotification(
                    title: "Check-In Reminder",
                    body: "It's been a while since your last drink. Would you like to check in with your emergency contacts?",
                    date: reminderTime,
                    identifier: "check_in_reminder",
                    categoryIdentifier: "EMERGENCY_CATEGORY"
                )
            }
        }
        
        // Hydration reminder
        func scheduleHydrationReminder() {
            let reminderTime = Date().addingTimeInterval(60 * 60) // 1 hour from now
            
            scheduleNotification(
                title: "Hydration Reminder",
                body: "Remember to drink water between alcoholic beverages to stay hydrated.",
                date: reminderTime,
                identifier: "hydration_reminder"
            )
        }
        
        // Schedule emergency check-in if user hasn't interacted with app
        func scheduleInactivityCheckIn(lastActiveTime: Date) {
            let checkInTime = lastActiveTime.addingTimeInterval(2 * 60 * 60) // 2 hours from last activity
            
            // Only schedule if check-in time is in the future
            if checkInTime > Date() {
                scheduleNotification(
                    title: "Are You OK?",
                    body: "We haven't noticed any activity in a while. Tap to check in or alert your emergency contacts.",
                    date: checkInTime,
                    identifier: "inactivity_check_in",
                    categoryIdentifier: "EMERGENCY_CATEGORY"
                )
            }
        }
    }
