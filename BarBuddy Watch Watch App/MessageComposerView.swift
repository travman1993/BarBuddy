//
//  MessageComposerView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.

// This is a special version for watchOS
#if os(watchOS)
import SwiftUI

// WatchOS version of message composer (simplified since MFMessageComposeViewController isn't available)
struct MessageComposerView: View {
    let recipients: [String]
    let body: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Message Preview")
                .font(.headline)
            
            Text("To: \(recipients.joined(separator: ", "))")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            Text(body)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text("Messages can only be sent from the paired iPhone.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Send from iPhone") {
                // This would trigger a request to the iPhone app to send the message
                // In a real implementation, this would use WatchConnectivity to pass the
                // message details to the iPhone
                sendMessageFromPhone()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
    }
    
    private func sendMessageFromPhone() {
        // Use WatchSessionManager to send the message info to the iPhone
        WatchSessionManager.shared.sendMessageRequest(
            recipients: recipients,
            body: body
        )
    }
}

// Add this method to your WatchSessionManager
extension WatchSessionManager {
    func sendMessageRequest(recipients: [String], body: String) {
        if session.activationState == .activated {
            let message: [String: Any] = [
                "action": "sendMessage",
                "recipients": recipients,
                "body": body
            ]
            
            session.sendMessage(message, replyHandler: { reply in
                print("Message request sent to iPhone")
            }, errorHandler: { error in
                print("Error sending message request: \(error.localizedDescription)")
            })
        }
    }
}
#endif
