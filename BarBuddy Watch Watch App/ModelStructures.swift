//
//  ModelStructures.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/24/25.
//                                                                                                                                                                                                                                                                                                                                  

import Foundation

// Enum for drink types
public enum DrinkType: String, Codable, CaseIterable {
    case beer = "Beer"
    case wine = "Wine"
    case cocktail = "Cocktail"
    case shot = "Shot"
    case other = "Other"
    
    public var defaultSize: Double {
        switch self {
        case .beer: return 12.0 // 12 oz
        case .wine: return 5.0 // 5 oz
        case .cocktail: return 4.0 // 4 oz
        case .shot: return 1.5 // 1.5 oz
        case .other: return 8.0 // 8 oz default
        }
    }
    
    public var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0 // 5%
        case .wine: return 12.0 // 12%
        case .cocktail: return 15.0 // 15%
        case .shot: return 40.0 // 40%
        case .other: return 10.0 // 10% default
        }
    }
    
    public var icon: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍸"
        case .shot: return "🥃"
        case .other: return "🍹"
        }
    }
}

// Enum for biological gender (used for BAC calculation)
public enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

// Struct for a single drink
public struct Drink: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: DrinkType
    public let size: Double // in fluid ounces
    public let alcoholPercentage: Double // as a percentage (e.g., 5.0 for 5%)
    public let timestamp: Date
    
    public init(type: DrinkType, size: Double, alcoholPercentage: Double, timestamp: Date) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
    }
    
    // Calculate standard drinks
    // A standard drink is defined as 0.6 fl oz of pure alcohol
    public var standardDrinks: Double {
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
}

// Enum for safety status
public enum SafetyStatus: String, Codable, Hashable {
    case safe = "Safe to Drive"
    case borderline = "Borderline"
    case unsafe = "Call a Ride"
    
    public var color: String {
        switch self {
        case .safe: return "green"
        case .borderline: return "yellow"
        case .unsafe: return "red"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
}

#if os(watchOS)
// Adding a minimal EmergencyContactManager stub for Watch app
class EmergencyContactManager {
    static let shared = EmergencyContactManager()
    
    var emergencyContacts: [EmergencyContact] = []
    
    func callEmergencyContact(_ contact: EmergencyContact) {
        // This would be implemented on iOS
        print("Would call \(contact.name) at \(contact.phoneNumber)")
    }
    
    func saveContacts() {
        // Simple stub
    }
}

// A minimal emergency contact implementation for Watch
struct EmergencyContact: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var phoneNumber: String
    public var relationshipType: String
    public var sendAutomaticTexts: Bool
    
    public init(name: String, phoneNumber: String, relationshipType: String, sendAutomaticTexts: Bool = false) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationshipType = relationshipType
        self.sendAutomaticTexts = sendAutomaticTexts
    }
}
#endif
