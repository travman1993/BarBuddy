//
//  ModelStructures.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/21/25.
//
import Foundation

// MARK: - Drink Type Enumeration
public enum DrinkType: String, Codable, CaseIterable, Hashable {
    case beer = "Beer"
    case wine = "Wine"
    case cocktail = "Cocktail"
    case shot = "Shot"
    case other = "Other"
    
    // Default serving sizes (in fluid ounces)
    public var defaultSize: Double {
        switch self {
        case .beer: return 12.0     // Standard can
        case .wine: return 5.0      // Standard wine pour
        case .cocktail: return 4.0  // Standard cocktail
        case .shot: return 1.5      // Standard shot
        case .other: return 8.0     // Default for other drinks
        }
    }
    
    // Default alcohol percentages
    public var defaultAlcoholPercentage: Double {
        switch self {
        case .beer: return 5.0      // Average beer
        case .wine: return 12.0     // Average wine
        case .cocktail: return 15.0 // Average cocktail
        case .shot: return 40.0     // Average spirits
        case .other: return 10.0    // Default for other
        }
    }
    
    // Emoji representation
    public var icon: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍸"
        case .shot: return "🥃"
        case .other: return "🍹"
        }
    }
    
    // Color mapping for UI
    public var color: Color {
        switch self {
        case .beer: return .beerColor
        case .wine: return .wineColor
        case .cocktail: return .cocktailColor
        case .shot: return .shotColor
        case .other: return .appTextSecondary
        }
    }
}

// MARK: - Gender Enumeration
public enum Gender: String, Codable, CaseIterable, Hashable {
    case male = "Male"
    case female = "Female"
    
    // Biological factors for BAC calculation
    public var bodyWaterConstant: Double {
        switch self {
        case .male: return 0.68
        case .female: return 0.55
        }
    }
}

// MARK: - Safety Status Enumeration
public enum SafetyStatus: String, Codable, Hashable {
    case safe = "Safe to Drive"
    case borderline = "Borderline"
    case unsafe = "Call a Ride"
    
    // Color representation for UI
    public var color: Color {
        switch self {
        case .safe: return .safe
        case .borderline: return .warning
        case .unsafe: return .danger
        }
    }
    
    // System image for visual representation
    public var systemImage: String {
        switch self {
        case .safe: return "checkmark.circle"
        case .borderline: return "exclamationmark.triangle"
        case .unsafe: return "xmark.octagon"
        }
    }
}

// MARK: - Drink Structure
public struct Drink: Identifiable, Codable, Hashable {
    public let id: UUID
    public let type: DrinkType
    public let size: Double        // in fluid ounces
    public let alcoholPercentage: Double
    public let timestamp: Date
    
    // Initializer
    public init(
        type: DrinkType,
        size: Double,
        alcoholPercentage: Double,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.type = type
        self.size = size
        self.alcoholPercentage = alcoholPercentage
        self.timestamp = timestamp
    }
    
    // Calculate standard drinks
    public var standardDrinks: Double {
        // A standard drink is 0.6 fl oz of pure alcohol
        let pureAlcohol = size * (alcoholPercentage / 100)
        return pureAlcohol / 0.6
    }
    
    // Estimated calories
    public var estimatedCalories: Int {
        // Alcohol calories: 7 calories per gram of alcohol
        let alcoholGrams = size * (alcoholPercentage / 100) * 0.789
        let alcoholCalories = Int(alcoholGrams * 7)
        
        // Additional calories from carbs
        let carbCalories: Int
        switch type {
        case .beer: carbCalories = Int(size * 13)
        case .wine: carbCalories = Int(size * 4)
        case .cocktail: carbCalories = Int(size * 12)
        case .shot: carbCalories = Int(size * 2)
        case .other: carbCalories = Int(size * 8)
        }
        
        return alcoholCalories + carbCalories
    }
}

// MARK: - User Profile Structure
public struct UserProfile: Codable, Hashable {
    public var weight: Double       // in pounds
    public var gender: Gender
    public var emergencyContacts: [EmergencyContact]
    public var height: Double?      // Optional height in inches
    
    // Initializer with default values
    public init(
        weight: Double = 160.0,
        gender: Gender = .male,
        emergencyContacts: [EmergencyContact] = [],
        height: Double? = nil
    ) {
        self.weight = weight
        self.gender = gender
        self.emergencyContacts = emergencyContacts
        self.height = height
    }
    
    // Calculated BMI (if height is available)
    public var bmi: Double? {
        guard let height = height else { return nil }
        let heightInMeters = height * 0.0254
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Estimated body water percentage
    public var bodyWaterPercentage: Double {
        // More accurate estimation based on gender and body composition
        return gender == .male ? 0.58 : 0.49
    }
}

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

// MARK: - BAC Share Structure
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

