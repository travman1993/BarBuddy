import Foundation
import SwiftUI

class StorageService {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - User Storage
    
    // Save a user
    func saveUser(_ user: User) async throws -> User {
        var updatedUser = user
        updatedUser.updatedAt = Date()
        let data = try encoder.encode(updatedUser)
        
        userDefaults.set(data, forKey: "user_\(user.id)")
        return updatedUser
    }
    
    // Get a user by ID
    func getUser(id: String) async throws -> User? {
        guard let data = userDefaults.data(forKey: "user_\(id)") else {
            return nil
        }
        
        return try decoder.decode(User.self, from: data)
    }
    
    // Check if user exists
    func userExists(id: String) async throws -> Bool {
        return userDefaults.data(forKey: "user_\(id)") != nil
    }
    
    // Delete a user
    func deleteUser(id: String) async throws {
        userDefaults.removeObject(forKey: "user_\(id)")
    }
    
    // MARK: - Drink Storage
    
    // Save a drink
    func saveDrink(_ drink: Drink) async throws -> Drink {
        let data = try encoder.encode(drink)
        userDefaults.set(data, forKey: "drink_\(drink.id)")
        
        // Update drink list for user
        await updateDrinkList(userId: drink.userId, drinkId: drink.id, isDelete: false)
        
        return drink
    }
    
    // Get a drink by ID
    func getDrink(id: String) async throws -> Drink? {
        guard let data = userDefaults.data(forKey: "drink_\(id)") else {
            return nil
        }
        
        return try decoder.decode(Drink.self, from: data)
    }
    
    // Delete a drink
    func deleteDrink(id: String) async throws {
        // Get the drink to find the user ID
        if let drink = try await getDrink(id: id) {
            userDefaults.removeObject(forKey: "drink_\(id)")
            await updateDrinkList(userId: drink.userId, drinkId: id, isDelete: true)
        }
    }
    
    // Get all drinks for a user
    func getUserDrinks(userId: String) async throws -> [Drink] {
        let drinkIds = userDefaults.stringArray(forKey: "user_\(userId)_drinks") ?? []
        var drinks: [Drink] = []
        
        for id in drinkIds {
            if let drink = try await getDrink(id: id) {
                drinks.append(drink)
            }
        }
        
        return drinks.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Get drinks in a time range
    func getDrinksInTimeRange(userId: String, start: Date, end: Date) async throws -> [Drink] {
        let allDrinks = try await getUserDrinks(userId: userId)
        return allDrinks.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    // Helper to update the list of drinks for a user
    private func updateDrinkList(userId: String, drinkId: String, isDelete: Bool) async {
        let key = "user_\(userId)_drinks"
        var drinkIds = userDefaults.stringArray(forKey: key) ?? []
        
        if isDelete {
            drinkIds.removeAll { $0 == drinkId }
        } else if !drinkIds.contains(drinkId) {
            drinkIds.append(drinkId)
        }
        
        userDefaults.set(drinkIds, forKey: key)
    }
    
    // MARK: - Emergency Contact Storage
    
    // Save an emergency contact
    func saveEmergencyContact(_ contact: EmergencyContact) async throws -> EmergencyContact {
        var updatedContact = contact
        updatedContact.updatedAt = Date()
        let data = try encoder.encode(updatedContact)
        
        userDefaults.set(data, forKey: "contact_\(contact.id)")
        
        // Update contact list for user
        await updateContactList(userId: contact.userId, contactId: contact.id, isDelete: false)
        
        return updatedContact
    }
    
    // Get a contact by ID
    func getEmergencyContact(id: String) async throws -> EmergencyContact? {
        guard let data = userDefaults.data(forKey: "contact_\(id)") else {
            return nil
        }
        
        return try decoder.decode(EmergencyContact.self, from: data)
    }
    
    // Delete a contact
    func deleteEmergencyContact(id: String) async throws {
        // Get the contact to find the user ID
        if let contact = try await getEmergencyContact(id: id) {
            userDefaults.removeObject(forKey: "contact_\(id)")
            await updateContactList(userId: contact.userId, contactId: id, isDelete: true)
        }
    }
    
    // Get all contacts for a user
    func getUserEmergencyContacts(userId: String) async throws -> [EmergencyContact] {
        let contactIds = userDefaults.stringArray(forKey: "user_\(userId)_contacts") ?? []
        var contacts: [EmergencyContact] = []
        
        for id in contactIds {
            if let contact = try await getEmergencyContact(id: id) {
                contacts.append(contact)
            }
        }
        
        return contacts
    }
    
    // Helper to update the list of contacts for a user
    private func updateContactList(userId: String, contactId: String, isDelete: Bool) async {
        let key = "user_\(userId)_contacts"
        var contactIds = userDefaults.stringArray(forKey: key) ?? []
        
        if isDelete {
            contactIds.removeAll { $0 == contactId }
        } else if !contactIds.contains(contactId) {
            contactIds.append(contactId)
        }
        
        userDefaults.set(contactIds, forKey: key)
    }
    
    // MARK: - Settings Storage
    
    // Save settings
    func saveSettings(_ settings: Settings) async throws {
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: "app_settings")
    }
    
    // Get settings
    func getSettings() async throws -> Settings {
        guard let data = userDefaults.data(forKey: "app_settings") else {
            return Settings.default
        }
        
        return try decoder.decode(Settings.self, from: data)
    }
    
    // MARK: - BAC Estimate Storage
    
    // Save BAC estimate
    func saveBAC(_ bac: BACEstimate, userId: String) async throws {
        let data = try encoder.encode(bac)
        userDefaults.set(data, forKey: "bac_\(userId)")
    }
    
    // Get BAC estimate for user
    func getBAC(userId: String) async throws -> BACEstimate? {
        guard let data = userDefaults.data(forKey: "bac_\(userId)") else {
            return nil
        }
        
        return try decoder.decode(BACEstimate.self, from: data)
    }
}
