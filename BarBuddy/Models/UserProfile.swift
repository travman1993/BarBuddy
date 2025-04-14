//
//  UserProfile.swift
//  BarBuddy
//

import Foundation

/**
 * Represents a user's profile information used for calculations.
 *
 * The profile includes biological factors that affect alcohol processing,
 * such as weight and gender, as well as optional personal information.
 */
public struct UserProfile: Codable, Hashable {
    /// User's weight in pounds
    public var weight: Double
    
    /// User's biological sex
    public var gender: Gender
    
    /// List of user's emergency contacts
    public var emergencyContacts: [EmergencyContact]
    
    /// Optional height in inches
    public var height: Double?
    
    /**
     * Initializes a new UserProfile with the specified values.
     *
     * - Parameters:
     *   - weight: User's weight in pounds (defaults to 160)
     *   - gender: User's biological sex (defaults to male)
     *   - emergencyContacts: List of emergency contacts (defaults to empty)
     *   - height: Optional height in inches
     */
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
    
    /**
     * Calculates the user's Body Mass Index (BMI) if height is available.
     */
    public var bmi: Double? {
        guard let height = height else { return nil }
        let heightInMeters = height * 0.0254
        return weight / (heightInMeters * heightInMeters)
    }
    
    /**
     * Estimates the user's body water percentage based on gender.
     */
    public var bodyWaterPercentage: Double {
        // More accurate estimation based on gender and body composition
        return gender == .male ? 0.58 : 0.49
    }
}
