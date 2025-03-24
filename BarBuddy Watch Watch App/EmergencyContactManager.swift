//
//  EmergencyContactManager.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.

import Foundation
import SwiftUI

// Import iOS-specific frameworks conditionally
#if os(iOS)
import Contacts
import ContactsUI
import MessageUI
#endif

class EmergencyContactManager: NSObject, ObservableObject {
    static let shared = EmergencyContactManager()
    
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isShowingContactPicker = false
    @Published var isShowingMessageComposer = false
    @Published var selectedContact: EmergencyContact?
    @Published var messageText = ""
    
    override init() {
        super.init()
        loadContacts()
    }
    
    // MARK: - Contact Management
    
    func loadContacts() {
        if let data = UserDefaults.standard.data(forKey: "emergencyContacts") {
            if let decoded = try? JSONDecoder().decode([EmergencyContact].self, from: data) {
                self.emergencyContacts = decoded
            }
        }
    }
    
    func saveContacts() {
        if let encoded = try? JSONEncoder().encode(emergencyContacts) {
            UserDefaults.standard.set(encoded, forKey: "emergencyContacts")
        }
    }
    
    func addContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveContacts()
    }
    
    func updateContact(_ contact: EmergencyContact) {
        if let index = emergencyContacts.firstIndex(where: { $0.id == contact.id }) {
            emergencyContacts[index] = contact
            saveContacts()
        }
    }
    
    func removeContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
    
    // MARK: - Emergency Messaging
    
    func sendEmergencyBACUpdate(bac: Double, timeUntilSober: TimeInterval) {
        // Get only contacts that have automatic texts enabled
        let eligibleContacts = emergencyContacts.filter { $0.sendAutomaticTexts }
        
        if eligibleContacts.isEmpty {
            return
        }
        
        // Format message
        let soberTime = formatTimeInterval(timeUntilSober)
        let message = "BarBuddy Automatic Alert: My current BAC is \(String(format: "%.3f", bac)). I'll be safe to drive in approximately \(soberTime)."
        
        for contact in eligibleContacts {
            sendMessage(to: contact, message: message)
        }
    }
    
    func sendSafetyCheckInMessage(to contact: EmergencyContact) {
        let message = "Hi, just checking in to let you know I made it home safely. (Sent via BarBuddy)"
        sendMessage(to: contact, message: message)
    }
    
    func sendCustomMessage(to contact: EmergencyContact, message: String) {
        sendMessage(to: contact, message: message)
    }
    
    func sendCurrentLocation(to contact: EmergencyContact) {
        // In a real app, this would get the user's location
        // and format it as a message with coordinates or a map link
        let message = "BarBuddy Emergency: I need help. Here is my current location: [Location would be included here]"
        sendMessage(to: contact, message: message)
    }
    
    func sendMessage(to contact: EmergencyContact, message: String) {
        #if os(iOS)
        self.selectedContact = contact
        self.messageText = message
        self.isShowingMessageComposer = true
        #else
        // On watchOS, we'd send a request to the paired iPhone to send the message
        // This is a simplified version
        print("Would send message to \(contact.name): \(message)")
        #endif
    }
    
    // MARK: - Emergency Call
    
    func callEmergencyContact(_ contact: EmergencyContact) {
        #if os(iOS)
        let formattedNumber = contact.phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if let url = URL(string: "tel://\(formattedNumber)") {
            UIApplication.shared.open(url)
        }
        #else
        // On watchOS, we can't directly make phone calls
        print("Would call emergency contact: \(contact.name)")
        #endif
    }
    
    func callEmergencyServices() {
        #if os(iOS)
        if let url = URL(string: "tel://911") {
            UIApplication.shared.open(url)
        }
        #else
        // On watchOS, we can't directly make phone calls
        print("Would call emergency services (911)")
        #endif
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) hours and \(minutes) minutes"
        } else {
            return "\(minutes) minutes"
        }
    }
}

// MARK: - watchOS-compatible versions of UI components

#if os(watchOS)
// Simple contact picker for watchOS
struct ContactPickerView: View {
    @EnvironmentObject var contactManager: EmergencyContactManager
    @Environment(\.presentationMode) var presentationMode
    var onSelectContact: (EmergencyContact) -> Void
    
    var body: some View {
        List {
            ForEach(contactManager.emergencyContacts) { contact in
                Button(action: {
                    onSelectContact(contact)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(contact.name)
                }
            }
            
            if contactManager.emergencyContacts.isEmpty {
                Text("No emergency contacts")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Choose Contact")
    }
}

#else
// MARK: - iOS Specific Components

// Message Composer Delegate
extension EmergencyContactManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// Contact Picker UI
struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onSelectContact: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelectContact(contact)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Message Composer UI
struct MessageComposerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var recipients: [String]
    var body: String
    var delegate: MFMessageComposeViewControllerDelegate
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.recipients = recipients
        composer.body = body
        composer.messageComposeDelegate = delegate
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}
#endif
