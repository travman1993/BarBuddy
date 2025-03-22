//
//  ModelStructures.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation

// Enum for drink types
enum DrinkType: String, Codable, CaseIterable {
    case beer = "Beer"
    case wine = "Wine"
    case cocktail = "Cocktail"
    case shot = "Shot"
    case other = "Other"
    
    var defaultSize: Double {
        switch self {
        case .beer: return 12.0 // 12 oz
        case .wine: return 5.0 // 5 oz
        case .cocktail: return 4.0 // 4 oz
        case .shot: return 1.5 // 1.5 oz
        case .other: return 8.0 // 8 oz default
        }
    }
    
    var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0 // 5%
        case .wine: return 12.0 // 12%
        case .cocktail: return 15.0 // 15%
        case .shot: return 40.0 // 40%
        case .other: return 10.0 // 10% default
        }
    }
    
    var icon: String {
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
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

// Struct for a single drink
struct Drink: Identifiable, Codable {
    let id: UUID
    let type: DrinkType
    let size: Double // in fluid ounces
    let alcoholPercentage: Double // as a percentage (e.g., 5.0 for 5%)
    let timestamp: Date
    
    init(type: DrinkType, size: Double, alcoholPercentage: Double, timestamp: Date) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
    }
    
    // Calculate standard drinks
    // A standard drink is defined as 0.6 fl oz of pure alcohol
    var standardDrinks: Double {
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
}

// Struct for user profile
struct UserProfile: Codable {
    var weight: Double // in pounds
    var gender: Gender
    var emergencyContacts: [EmergencyContact]
    
    init(weight: Double = 160.0, gender: Gender = .male, emergencyContacts: [EmergencyContact] = []) {
        self.weight = weight
        self.gender = gender
        self.emergencyContacts = emergencyContacts
    }
}

// Struct for emergency contact
struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var relationshipType: String
    var sendAutomaticTexts: Bool
    
    init(name: String, phoneNumber: String, relationshipType: String, sendAutomaticTexts: Bool = false) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationshipType = relationshipType
        self.sendAutomaticTexts = sendAutomaticTexts
    }
}

// Struct for BAC sharing
struct BACShare: Identifiable, Codable {
    let id: UUID
    let bac: Double
    let message: String
    let timestamp: Date
    var expiresAt: Date
    
    init(bac: Double, message: String, expiresAfter hours: Double = 2.0) {
        self.id = UUID()
        self.bac = bac
        self.message = message
        self.timestamp = Date()
        self.expiresAt = Date().addingTimeInterval(hours * 3600)
    }
    
    var isActive: Bool {
        return Date() < expiresAt
    }
    
    var safetyStatus: SafetyStatus {
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
enum SafetyStatus: String, Codable {
    case safe = "Safe to Drive"
    case borderline = "Borderline"
    case unsafe = "Call a Ride"
    
    var color: String {
        switch self {
        case .safe: return "green"
        case .borderline: return "yellow"
        case .unsafe: return "red"
        }
    }
    
    var systemImage: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
}
