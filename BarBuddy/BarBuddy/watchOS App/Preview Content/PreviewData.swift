//
//  PreviewData.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//
import Foundation

// Sample data for previews
struct PreviewData {
    // Sample User
    static let user = User(
        id: "preview-user-id",
        name: "Preview User",
        gender: .male,
        weight: 180.0,
        age: 30,
        hasAcceptedDisclaimer: true
    )
    
    // Sample Drinks
    static let drinks: [Drink] = [
        Drink(
            id: "drink1",
            userId: "preview-user-id",
            type: .beer,
            name: "IPA",
            alcoholPercentage: 6.5,
            amount: 12.0,
            timestamp: Date().addingTimeInterval(-1 * 60 * 60), // 1 hour ago
            location: "Local Bar"
        ),
        Drink(
            id: "drink2",
            userId: "preview-user-id",
            type: .wine,
            name: "Red Wine",
            alcoholPercentage: 13.5,
            amount: 5.0,
            timestamp: Date().addingTimeInterval(-2 * 60 * 60) // 2 hours ago
        ),
        Drink(
            id: "drink3",
            userId: "preview-user-id",
            type: .cocktail,
            name: "Margarita",
            alcoholPercentage: 12.0,
            amount: 8.0,
            timestamp: Date().addingTimeInterval(-3 * 60 * 60) // 3 hours ago
        )
    ]
    
    // Sample BAC Estimate
    static let bacEstimate = BACEstimate(
        bac: 0.065,
        timestamp: Date(),
        soberTime: Date().addingTimeInterval(4 * 60 * 60), // 4 hours from now
        legalTime: Date().addingTimeInterval(30 * 60), // 30 minutes from now
        drinkIds: ["drink1", "drink2", "drink3"]
    )
    
    // Sample Emergency Contacts
    static let emergencyContacts: [EmergencyContact] = [
        EmergencyContact(
            id: "contact1",
            userId: "preview-user-id",
            name: "Emergency Contact 1",
            phoneNumber: "5551234567",
            isPrimary: true
        ),
        EmergencyContact(
            id: "contact2",
            userId: "preview-user-id",
            name: "Emergency Contact 2",
            phoneNumber: "5559876543",
            isPrimary: false
        )
    ]
}
