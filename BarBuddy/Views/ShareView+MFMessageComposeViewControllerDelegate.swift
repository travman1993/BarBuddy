//
//  ShareView+MFMessageComposeViewControllerDelegate.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import SwiftUI
import MessageUI

extension ShareView: NSObjectProtocol, MFMessageComposeViewControllerDelegate {
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
            if !selectedContacts.isEmpty {
            }
        @unknown default:
            print("Unknown message result")
        }
    }
}
