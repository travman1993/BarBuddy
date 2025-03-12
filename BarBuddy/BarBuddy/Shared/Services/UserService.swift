import Foundation

class UserService {
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
    }
    
    // Get user by ID
    func getUser(id: String) async throws -> User? {
        return try await storageService.getUser(id: id)
    }
    
    // Create a new user
    func createUser(user: User) async throws -> User {
        var newUser = user
        if newUser.id.isEmpty {
            newUser.id = UUID().uuidString
        }
        return try await storageService.saveUser(newUser)
    }
    
    // Update an existing user
    func updateUser(user: User) async throws -> User {
        return try await storageService.saveUser(user)
    }
    
    // Check if user exists
    func userExists(id: String) async throws -> Bool {
        return try await storageService.userExists(id: id)
    }
    
    // Get or create user (useful for first launch)
    func getOrCreateUser(id: String) async throws -> User {
        if let existingUser = try await getUser(id: id) {
            return existingUser
        }
        
        // Create default user
        let now = Date()
        let newUser = User(
            id: id,
            gender: .male, // Default
            weight: 160, // Default in pounds
            age: 25, // Default
            createdAt: now,
            updatedAt: now
        )
        
        return try await createUser(user: newUser)
    }
    
    // Accept disclaimer
    func acceptDisclaimer(userId: String) async throws -> User {
        guard var user = try await getUser(id: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        user.hasAcceptedDisclaimer = true
        user.updatedAt = Date()
        
        return try await updateUser(user: user)
    }
    
    // Update user profile details
    func updateUserProfile(userId: String, name: String? = nil, gender: Gender? = nil, weight: Double? = nil, age: Int? = nil) async throws -> User {
        guard var user = try await getUser(id: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        if let name = name {
            user.name = name
        }
        
        if let gender = gender {
            user.gender = gender
        }
        
        if let weight = weight {
            user.weight = weight
        }
        
        if let age = age {
            user.age = age
        }
        
        user.updatedAt = Date()
        
        return try await updateUser(user: user)
    }
    
    // Add emergency contact ID to user
    func addEmergencyContact(userId: String, contactId: String) async throws -> User {
        guard var user = try await getUser(id: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        if !user.emergencyContactIds.contains(contactId) {
            user.emergencyContactIds.append(contactId)
            user.updatedAt = Date()
            return try await updateUser(user: user)
        }
        
        return user
    }
    
    // Remove emergency contact ID from user
    func removeEmergencyContact(userId: String, contactId: String) async throws -> User {
        guard var user = try await getUser(id: userId) else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        if user.emergencyContactIds.contains(contactId) {
            user.emergencyContactIds.removeAll { $0 == contactId }
            user.updatedAt = Date()
            return try await updateUser(user: user)
        }
        
        return user
    }
}
