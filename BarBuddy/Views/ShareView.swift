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
