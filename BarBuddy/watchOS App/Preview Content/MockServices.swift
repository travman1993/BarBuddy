//
//  MockServices.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/12/25.
//
import Foundation
import Combine

// Mock services for preview
class MockStorageService: StorageService {
    override func getUser(id: String) async throws -> User? {
        return PreviewData.user
    }
    
    override func getDrinksInTimeRange(userId: String, start: Date, end: Date) async throws -> [Drink] {
        return PreviewData.drinks
    }
    
    override func getBAC(userId: String) async throws -> BACEstimate? {
        return PreviewData.bacEstimate
    }
    
    override func getUserEmergencyContacts(userId: String) async throws -> [EmergencyContact] {
        return PreviewData.emergencyContacts
    }
}

class MockDrinkService: DrinkService {
    override func getDrinksInRange(userId: String, start: Date, end: Date) async throws -> [Drink] {
        return PreviewData.drinks
    }
    
    override func addStandardDrink(userId: String, type: DrinkType, location: String? = nil) async throws -> Drink {
        return Drink.example(type: type)
    }
}

class MockEmergencyService: EmergencyService {
    override func getUserContacts(userId: String) async throws -> [EmergencyContact] {
        return PreviewData.emergencyContacts
    }
    
    override func sendEmergencyAlert(userId: String, userName: String, location: String? = nil, customMessage: String? = nil) async throws {
        // Simulate sending alert
    }
    
    override func sendCheckInMessage(userId: String, userName: String, location: String? = nil, onlyPrimary: Bool = false) async throws {
        // Simulate sending check-in
    }
}
