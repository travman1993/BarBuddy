//
//  ShareView+MFMessageComposeViewControllerDelegate.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import SwiftUI
import MessageUI

// MARK: - Message Composer Delegate
// Create a separate delegate class instead of extending ShareView
class ShareViewMessageDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    var onComplete: () -> Void
    
    init(onComplete: @escaping () -> Void = {}) {
        self.onComplete = onComplete
        super.init()
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Dismiss the message compose view controller
        controller.dismiss(animated: true, completion: nil)
        
        // Handle the result
        switch result {
        case .cancelled:
            print("Message cancelled")
        case .failed:
            print("Message failed")
            // You might want to show an alert here
        case .sent:
            print("Message sent")
            // Successfully shared
        @unknown default:
            print("Unknown message result")
        }
        
        // Call completion handler
        onComplete()
    }
}
