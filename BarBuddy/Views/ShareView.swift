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
    
    @Published var activeShares: [DrinkShare] = []
    @Published var contacts: [Contact] = []
    
    private let maxActiveShares = 10
    private let defaultShareDuration: TimeInterval = 2 * 3600 // 2 hours
    private let logger = Logger(subsystem: "com.yourapp.ShareManager", category: "ShareManagement")
    
    let messageTemplates = [
        "Checking in with my current status.",
        "Just tracking my drinks for safety.",
        "Staying responsible tonight.",
        "Keeping an eye on my drinking.",
        "Safety first."
    ]
    
    private init() {
        loadShares()
        loadContacts()
        cleanupExpiredShares()
    }
    
    func addShare(drinkCount: Double, drinkLimit: Double, message: String? = nil, expirationHours: Double? = nil) -> DrinkShare {
        cleanupExpiredShares()
        
        if activeShares.count >= maxActiveShares {
            logger.warning("Max active shares reached. Removing oldest share.")
            activeShares.removeFirst()
        }
        
        let expirationTime = expirationHours ?? defaultShareDuration / 3600
        let newShare = DrinkShare(
            drinkCount: drinkCount,
            drinkLimit: drinkLimit,
            message: message ?? messageTemplates.randomElement()!,
            expiresAfter: expirationTime
        )
        
        activeShares.append(newShare)
        saveShares()
        
        return newShare
    }
    
    func removeShare(_ share: DrinkShare) {
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
            UserDefaults.standard.set(data, forKey: "activeDrinkShares")
            logger.info("Shares saved successfully.")
        } catch {
            logger.error("Error saving shares: \(error.localizedDescription)")
        }
    }
    
    private func loadShares() {
        guard let data = UserDefaults.standard.data(forKey: "activeDrinkShares") else {
            logger.info("No saved shares found.")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            activeShares = try decoder.decode([DrinkShare].self, from: data)
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
    
    func createShareMessage(drinkCount: Double, drinkLimit: Double, customMessage: String? = nil, includeLocation: Bool = false) -> String {
        let baseMessage = customMessage ?? messageTemplates.randomElement()!
        let drinkStatus = drinkCount >= drinkLimit 
            ? "reached my drink limit" 
            : "\(String(format: "%.1f", drinkCount)) of \(String(format: "%.1f", drinkLimit)) drinks"
        
        var fullMessage = "\(baseMessage)\n\nCurrent Status: \(drinkStatus)"
        
        if includeLocation {
            fullMessage += "\nApproximate Location: [Location would be included]"
        }
        
        return fullMessage
    }
    
    func prepareShareForWatch(share: DrinkShare) -> [String: Any] {
        return [
            "id": share.id.uuidString,
            "drinkCount": share.drinkCount,
            "drinkLimit": share.drinkLimit,
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

// MARK: - DrinkShare Structure
public struct DrinkShare: Identifiable, Codable, Hashable {
    public let id: UUID
    public let drinkCount: Double
    public let drinkLimit: Double
    public let message: String
    public let timestamp: Date
    public let expiresAt: Date
    
    // Initializer
    public init(
        drinkCount: Double,
        drinkLimit: Double,
        message: String,
        expiresAfter hours: Double = 2.0
    ) {
        self.id = UUID()
        self.drinkCount = drinkCount
        self.drinkLimit = drinkLimit
        self.message = message
        self.timestamp = Date()
        self.expiresAt = Date().addingTimeInterval(hours * 3600)
    }
    
    // Check if share is still active
    public var isActive: Bool {
        return Date() < expiresAt
    }
    
    // Determine safety status based on drink count
    public var safetyStatus: SafetyStatus {
        if drinkCount >= drinkLimit {
            return .unsafe
        } else if drinkCount >= drinkLimit * 0.75 {
            return .borderline
        } else {
            return .safe
        }
    }
}

struct ShareView: View {
    @EnvironmentObject var drinkTracker: DrinkTracker
    @StateObject private var shareManager = ShareManager.shared
    @StateObject private var emergencyContactManager = EmergencyContactManager.shared
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Initialize with first message template instead of empty string
    @State private var selectedMessage: String = ShareManager.shared.messageTemplates.first ?? "Checking in with my current status."
    @State private var includeLocation = false
    @State private var selectedContacts: Set<EmergencyContact> = []
    @State private var showingMessageComposer = false
    @State private var messageRecipients: [String] = []
    @State private var messageBody: String = ""
    
    var body: some View {
        // Main content without navigation wrapper
        let content = Form {
            // Current Drink Status Section
            Section(header: Text("YOUR CURRENT STATUS")) {
                HStack {
                    Text("Standard Drinks")
                    Spacer()
                    Text(String(format: "%.1f of %.1f", drinkTracker.standardDrinkCount, drinkTracker.drinkLimit))
                        .fontWeight(.bold)
                        .foregroundColor(getDrinkStatusColor())
                }
                
                HStack {
                    Text("Status")
                    Spacer()
                    Text(getDrinkStatusText())
                        .foregroundColor(getDrinkStatusColor())
                }
                
                if drinkTracker.timeUntilReset > 0 {
                    HStack {
                        Text("Resets In")
                        Spacer()
                        Text(formatTimeUntilReset(drinkTracker.timeUntilReset))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Message Customization Section
            Section(header: Text("SHARE MESSAGE")) {
                Picker("Pre-written Message", selection: $selectedMessage) {
                    ForEach(shareManager.messageTemplates, id: \.self) { template in
                        Text(template).tag(template)
                    }
                }
                
                Toggle("Include Approximate Location", isOn: $includeLocation)
            }
            
            // Emergency Contacts Selection Section
            Section(header: Text("SELECT CONTACTS")) {
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
        .background(Color("AppBackground"))
        
        // On iPhone, wrap in NavigationView; on iPad (when in a NavigationSplitView), just return the content
        if horizontalSizeClass == .compact {
            NavigationView {
                content
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
        } else {
            content
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
    }
    
    func shareStatus() {
        let message = shareManager.createShareMessage(
            drinkCount: drinkTracker.standardDrinkCount,
            drinkLimit: drinkTracker.drinkLimit,
            customMessage: selectedMessage.isEmpty ? nil : selectedMessage,
            includeLocation: includeLocation
        )
        
        // Create a share
        _ = shareManager.addShare(
            drinkCount: drinkTracker.standardDrinkCount,
            drinkLimit: drinkTracker.drinkLimit,
            message: selectedMessage.isEmpty ? nil : selectedMessage
        )

        // Include location if requested
        var completeMessage = message
        if includeLocation {
            let locationString = LocationManager.shared.getLocationString()
            completeMessage += "\nLocation: \(locationString)"
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
    
    private func getDrinkStatusColor() -> Color {
        if drinkTracker.standardDrinkCount >= drinkTracker.drinkLimit {
            return .red
        } else if drinkTracker.standardDrinkCount >= drinkTracker.drinkLimit * 0.75 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getDrinkStatusText() -> String {
        if drinkTracker.standardDrinkCount >= drinkTracker.drinkLimit {
            return "Limit Reached"
        } else if drinkTracker.standardDrinkCount >= drinkTracker.drinkLimit * 0.75 {
            return "Approaching Limit"
        } else {
            return "Under Limit"
        }
    }
    
    private func formatTimeUntilReset(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
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
