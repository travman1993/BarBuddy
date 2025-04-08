//
//  ShareView.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation
import SwiftUI
import Combine
import os
import MessageUI

class ShareManager: ObservableObject {
    static let shared = ShareManager()
    
    @Published var activeShares: [BACShare] = []
    @Published var contacts: [Contact] = []
    
    private let maxActiveShares = 10
    private let defaultShareDuration: TimeInterval = 2 * 3600 // 2 hours
    private let logger = Logger(subsystem: "com.yourapp.ShareManager", category: "ShareManagement")
    
    let messageTemplates = [
        "Checking in with my current status.",
        "Just tracking my BAC for safety.",
        "Staying responsible tonight.",
        "Keeping an eye on my drinking.",
        "Safety first."
    ]
    
    private init() {
        loadShares()
        loadContacts()
        cleanupExpiredShares()
    }
    
    func addShare(bac: Double, message: String? = nil, expirationHours: Double? = nil) -> BACShare {
        cleanupExpiredShares()
        
        if activeShares.count >= maxActiveShares {
            logger.warning("Max active shares reached. Removing oldest share.")
            activeShares.removeFirst()
        }
        
        let expirationTime = expirationHours ?? defaultShareDuration / 3600
        let newShare = BACShare(
            bac: bac,
            message: message ?? messageTemplates.randomElement()!,
            expiresAfter: expirationTime
        )
        
        activeShares.append(newShare)
        saveShares()
        
        return newShare
    }
    
    func removeShare(_ share: BACShare) {
        activeShares.removeAll { $0.id == share.id }
        saveShares()
    }
    
    private func cleanupExpiredShares() {
        let now = Date()
        let beforeCleanup = activeShares.count
        activeShares.removeAll { $0.expiresAt <= now }
        
        if beforeCleanup > activeShares.count {
            logger.info("\(beforeCleanup - self.activeShares.count) expired shares removed.")
        }
        saveShares()
    }
    
    private func saveShares() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(activeShares)
            UserDefaults.standard.set(data, forKey: "activeBACShares")
            logger.info("Shares saved successfully.")
        } catch {
            logger.error("Error saving shares: \(error.localizedDescription)")
        }
    }
    
    private func loadShares() {
        guard let data = UserDefaults.standard.data(forKey: "activeBACShares") else {
            logger.info("No saved shares found.")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            activeShares = try decoder.decode([BACShare].self, from: data)
            cleanupExpiredShares()
            logger.info("Shares loaded successfully.")
        } catch {
            logger.error("Error loading shares: \(error.localizedDescription)")
            activeShares = []
        }
    }
    
    private func loadContacts() {
        contacts = [
            Contact(id: "1", name: "Alex Johnson", phone: "555-123-4567"),
            Contact(id: "2", name: "Sam Williams", phone: "555-987-6543"),
            Contact(id: "3", name: "Jordan Lee", phone: "555-246-8101")
        ]
    }
    
    func createShareMessage(bac: Double, customMessage: String? = nil, includeLocation: Bool = false) -> String {
        let baseMessage = customMessage ?? messageTemplates.randomElement()!
        let bacString = String(format: "%.3f", bac)
        
        var fullMessage = "\(baseMessage)\n\nCurrent BAC: \(bacString)"
        
        if includeLocation {
            fullMessage += "\nApproximate Location: [Location would be included]"
        }
        
        return fullMessage
    }
    
    func prepareShareForWatch(share: BACShare) -> [String: Any] {
        return [
            "id": share.id.uuidString,
            "bac": share.bac,
            "message": share.message,
            "timestamp": share.timestamp,
            "expiresAt": share.expiresAt
        ]
    }
}

extension ShareManager {
    func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^\\+?[1-9]\\d{1,14}$"  // Supports international numbers
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }
    
    func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard digits.count >= 10 else { return phone }
        
        let areaCode = digits.prefix(3)
        let firstThree = digits.dropFirst(3).prefix(3)
        let lastFour = digits.dropFirst(6).prefix(4)
        
        return "(\(areaCode)) \(firstThree)-\(lastFour)"
    }
}
struct ShareView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @StateObject private var shareManager = ShareManager.shared
    @StateObject private var emergencyContactManager = EmergencyContactManager.shared
    
    @State private var selectedMessage: String = ""
    @State private var includeLocation = false
    @State private var selectedContacts: Set<EmergencyContact> = []
    @State private var showingMessageComposer = false
    @State private var messageRecipients: [String] = []
    @State private var messageBody: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Current BAC Section
                Section(header: Text("Your Current Status")) {
                    HStack {
                        Text("Blood Alcohol Content")
                        Spacer()
                        Text(String(format: "%.3f", drinkTracker.currentBAC))
                            .fontWeight(.bold)
                            .foregroundColor(getBACColor())
                    }
                    
                    HStack {
                        Text("Safety Status")
                        Spacer()
                        Text(getSafetyStatus())
                            .foregroundColor(getBACColor())
                    }
                }
                
                // Message Customization Section
                Section(header: Text("Share Message")) {
                    Picker("Pre-written Message", selection: $selectedMessage) {
                        ForEach(shareManager.messageTemplates, id: \.self) { template in
                            Text(template).tag(template)
                        }
                    }
                    
                    Toggle("Include Approximate Location", isOn: $includeLocation)
                }
                
                // Emergency Contacts Selection Section
                Section(header: Text("Select Contacts")) {
                    if emergencyContactManager.emergencyContacts.isEmpty {
                        Text("No emergency contacts added")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(emergencyContactManager.emergencyContacts, id: \.id) { contact in
                            MultipleSelectionRow(
                                title: contact.name,
                                subtitle: contact.phoneNumber,
                                isSelected: selectedContacts.contains(contact)
                            ) {
                                if selectedContacts.contains(contact) {
                                    selectedContacts.remove(contact)
                                } else {
                                    selectedContacts.insert(contact)
                                }
                            }
                        }
                    }
                }
                
                // Add Emergency Contact Button
                Section {
                    NavigationLink(destination: AddContactView { newContact in
                        emergencyContactManager.addContact(newContact)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Emergency Contact")
                        }
                    }
                }
                
                // Share Button
                Section {
                    Button(action: shareStatus) {
                        HStack {
                            Spacer()
                            Text("Share Status")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(selectedContacts.isEmpty)
                }
            }
            .navigationTitle("Share Status")
        }
        .sheet(isPresented: $showingMessageComposer) {
            #if os(iOS)
            MessageComposerView(
                recipients: messageRecipients,
                body: messageBody,
                delegate: ShareViewMessageDelegate()
            )
            #endif
        }
    }
    
    // Update in ShareView.swift
    func shareStatus() {
        let message = shareManager.createShareMessage(
            bac: drinkTracker.currentBAC,
            customMessage: selectedMessage.isEmpty ? nil : selectedMessage,
            includeLocation: includeLocation
        )
        
        // Create a share
        shareManager.addShare(
            bac: drinkTracker.currentBAC,
            message: selectedMessage.isEmpty ? nil : selectedMessage
        )
        
        // Include location if requested
        var completeMessage = message
        if includeLocation, let location = LocationManager.shared.getLocationString() {
            completeMessage += "\nLocation: \(location)"
        }
        
        // Prepare recipients and message for Message Composer
        messageRecipients = selectedContacts.map { $0.phoneNumber }
        messageBody = completeMessage
        
        #if os(iOS)
        if MessageComposerView.canSendText() {
            showingMessageComposer = true
        } else {
            // Fallback for devices that can't send SMS
            let shareSheet = UIActivityViewController(
                activityItems: [completeMessage],
                applicationActivities: nil
            )
            
            // Find the current UIWindow to present from
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = scene.windows.first?.rootViewController {
                shareSheet.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(shareSheet, animated: true)
            }
        }
        #endif
    }
    
    private func getBACColor() -> Color {
        if drinkTracker.currentBAC < 0.04 {
            return .green
        } else if drinkTracker.currentBAC < 0.08 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getSafetyStatus() -> String {
        if drinkTracker.currentBAC < 0.04 {
            return "Safe to Drive"
        } else if drinkTracker.currentBAC < 0.08 {
            return "Caution Advised"
        } else {
            return "Do Not Drive"
        }
    }
}

// Supporting view for multiple selection
struct MultipleSelectionRow: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

#Preview {
    ShareView()
        .environmentObject(DrinkTracker())
}
