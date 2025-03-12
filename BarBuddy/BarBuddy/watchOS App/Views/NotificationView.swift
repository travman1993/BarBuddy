//
//  NotificationView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// NotificationView.swift
// NotificationView.swift
import SwiftUI

struct NotificationView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 24))
                .foregroundColor(.red)
            
            Text("BarBuddy")
                .font(.headline)
            
            Spacer()
            
            Text("It's time to check your BAC level.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .padding()
    }
}

struct NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView {
        return NotificationView()
    }
    
    override func didReceive(_ notification: UNNotification) {
        // Extract notification content here if needed
    }
}
