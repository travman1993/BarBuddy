//
//  Untitled.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
#if os(iOS)
import SwiftUI
import MessageUI

// Fixed MessageComposerView
struct MessageComposerView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    var delegate: MFMessageComposeViewControllerDelegate
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.recipients = recipients
        messageComposeVC.body = body
        messageComposeVC.messageComposeDelegate = delegate
        return messageComposeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // No updates needed
    }
    
    // Check if the device can send text messages
    static func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
}

// MARK: - Preview
struct MessageComposerView_Previews: PreviewProvider {
    static var previews: some View {
        // Previews are not available for MFMessageComposeViewController
        Text("Message Composer View")
            .padding()
    }
}
#endif
