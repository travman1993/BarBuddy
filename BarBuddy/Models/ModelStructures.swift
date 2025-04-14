//
//  ModelStructures.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation
import SwiftUI

// MARK: - Emergency Contact Structure
public struct EmergencyContact: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var phoneNumber: String
    public var relationshipType: String
    public var sendAutomaticTexts: Bool
    
    // Initializer
    public init(
        name: String,
        phoneNumber: String,
        relationshipType: String,
        sendAutomaticTexts: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationshipType = relationshipType
        self.sendAutomaticTexts = sendAutomaticTexts
    }
    
    // Formatted phone number
    public var formattedPhoneNumber: String {
        // Basic phone number formatting
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleaned.count >= 10 else { return phoneNumber }
        
        let areaCode = cleaned.prefix(3)
        let firstThree = cleaned.dropFirst(3).prefix(3)
        let lastFour = cleaned.dropFirst(6).prefix(4)
        
        return "(\(areaCode)) \(firstThree)-\(lastFour)"
    }
}

// MARK: - Share Structure
public struct BACShare: Identifiable, Codable, Hashable {
    public let id: UUID
    public let bac: Double
    public let message: String
    public let timestamp: Date
    public let expiresAt: Date
    
    // Initializer
    public init(
        bac: Double,
        message: String,
        expiresAfter hours: Double = 2.0
    ) {
        self.id = UUID()
        self.bac = bac
        self.message = message
        self.timestamp = Date()
        self.expiresAt = Date().addingTimeInterval(hours * 3600)
    }
    
    // Check if share is still active
    public var isActive: Bool {
        return Date() < expiresAt
    }
    
    // Determine safety status based on BAC
    public var safetyStatus: SafetyStatus {
        if bac < 0.04 {
            return .safe
        } else if bac < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }
}

// MARK: - Temporary Shared Contacts
public struct Contact: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let phone: String
    
    // Initializer
    public init(id: String, name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
    
    // Get initials for display
    public var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2,
           let first = components.first?.first,
           let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = components.first?.first {
            return String(first)
        }
        return "?"
    }
}

