//
//  ModelStructures.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
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

// Struct for user profile
public struct UserProfile: Codable, Hashable {
    public var weight: Double // in pounds
    public var gender: Gender
    public var emergencyContacts: [EmergencyContact]
    
    public init(weight: Double = 160.0, gender: Gender = .male, emergencyContacts: [EmergencyContact] = []) {
        self.weight = weight
        self.gender = gender
        self.emergencyContacts = emergencyContacts
    }
}

// Struct for emergency contact
public struct EmergencyContact: Identifiable, Codable, Hashable {
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

// Struct for BAC sharing
public struct BACShare: Identifiable, Codable, Hashable {
    public let id: UUID
    public let bac: Double
    public let message: String
    public let timestamp: Date
    public var expiresAt: Date
    
    public init(bac: Double, message: String, expiresAfter hours: Double = 2.0) {
        self.id = UUID()
        self.bac = bac
        self.message = message
        self.timestamp = Date()
        self.expiresAt = Date().addingTimeInterval(hours * 3600)
    }
    
    public var isActive: Bool {
        return Date() < expiresAt
    }
    
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

// Friend model for sharing
public struct Friend: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let phone: String
    
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
    
    public static func == (lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id
    }
}
