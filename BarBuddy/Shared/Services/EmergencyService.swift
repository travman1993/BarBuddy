import Foundation

class EmergencyService {
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
    }
    
    // Add a new emergency contact
    func addContact(contact: EmergencyContact) async throws -> EmergencyContact {
        // If this is primary, update other primary contacts
        if contact.isPrimary {
            try await updateExistingPrimaryContacts(userId: contact.userId)
        }
        
        return try await storageService.saveEmergencyContact(contact)
    }
    
    // Update an existing contact
    func updateContact(contact: EmergencyContact) async throws -> EmergencyContact {
        // If this is being set as primary, update other primary contacts
        if contact.isPrimary {
            try await updateExistingPrimaryContacts(userId: contact.userId, excludeId: contact.id)
        }
        
        return try await storageService.saveEmergencyContact(contact)
    }
    
    // Delete a contact
    func deleteContact(id: String) async throws {
        try await storageService.deleteEmergencyContact(id: id)
    }
    
    // Get a contact by ID
    func getContact(id: String) async throws -> EmergencyContact? {
        return try await storageService.getEmergencyContact(id: id)
    }
    
    // Get all contacts for a user
    func getUserContacts(userId: String) async throws -> [EmergencyContact] {
        return try await storageService.getUserEmergencyContacts(userId: userId)
    }
    
    // Get the primary contact for a user
    func getPrimaryContact(userId: String) async throws -> EmergencyContact? {
        let contacts = try await getUserContacts(userId: userId)
        return contacts.first { $0.isPrimary }
    }
    
    // Set a contact as primary
    func setPrimaryContact(contactId: String, userId: String) async throws {
        // Update existing primary contacts
        try await updateExistingPrimaryContacts(userId: userId)
        
        // Set this contact as primary
        guard var contact = try await getContact(id: contactId) else {
            throw NSError(domain: "EmergencyService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Contact not found"])
        }
        
        contact.isPrimary = true
        contact.updatedAt = Date()
        
        _ = try await updateContact(contact: contact)
    }
    
    // Helper to update existing primary contacts
    private func updateExistingPrimaryContacts(userId: String, excludeId: String? = nil) async throws {
        let contacts = try await getUserContacts(userId: userId)
        let primaryContacts = contacts.filter { $0.isPrimary && (excludeId == nil || $0.id != excludeId) }
        
        for var contact in primaryContacts {
            contact.isPrimary = false
            contact.updatedAt = Date()
            _ = try await storageService.saveEmergencyContact(contact)
        }
    }
    
    // Send a check-in message to emergency contacts
    func sendCheckInMessage(userId: String, userName: String, location: String? = nil, onlyPrimary: Bool = false) async throws {
        // In a real app, this would integrate with messaging APIs
        // For now, we'll just simulate the functionality
        
        let contacts = try await getUserContacts(userId: userId)
        let targetContacts = onlyPrimary
            ? contacts.filter { $0.isPrimary }
            : contacts.filter { $0.enableAutoCheckIn }
        
        if targetContacts.isEmpty {
            throw NSError(domain: "EmergencyService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No eligible contacts found"])
        }
        
        let locationString = location != nil ? " Location: \(location!)" : ""
        let message = "\(userName) is checking in via BarBuddy app.\(locationString)"
        
        print("📱 Would send check-in message: \"\(message)\" to \(targetContacts.count) contacts")
        
        // Here you would integrate with a messaging service/API
    }
    
    // Send an emergency alert to contacts
    func sendEmergencyAlert(userId: String, userName: String, location: String? = nil, customMessage: String? = nil) async throws {
        // In a real app, this would integrate with messaging APIs
        // For now, we'll just simulate the functionality
        
        let contacts = try await getUserContacts(userId: userId)
        let alertContacts = contacts.filter { $0.enableEmergencyAlerts }
        
        if alertContacts.isEmpty {
            throw NSError(domain: "EmergencyService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No emergency alert contacts found"])
        }
        
        let locationString = location != nil ? " Location: \(location!)" : ""
        let customMessageString = customMessage != nil ? "\n\(customMessage!)" : ""
        
        let message = "⚠️ EMERGENCY ALERT: \(userName) needs help.\(customMessageString)\(locationString)"
        
        print("🚨 Would send emergency alert: \"\(message)\" to \(alertContacts.count) contacts")
        
        // Here you would integrate with a messaging service/API
    }
}
