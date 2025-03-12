import Foundation
import Combine

class UserViewModel: ObservableObject {
    private let userService = UserService()
    private let storageService = StorageService()
    
    @Published var currentUser: User = User.example
    @Published var isLoading = false
    @Published var isFirstLaunch = true
    @Published var hasAcceptedDisclaimer = false
    @Published var error: String?
    
    init() {
        loadUser()
    }
    
    private func loadUser() {
        isLoading = true
        
        Task {
            do {
                // Check for stored user ID
                if let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId) {
                    if let user = try await userService.getUser(id: userId) {
                        await updateUser(user)
                    } else {
                        // Create a new user if not found
                        let user = try await createNewUser(id: userId)
                        await updateUser(user)
                    }
                } else {
                    // Create a new user for first launch
                    let user = try await createNewUser()
                    await updateUser(user)
                    
                    // Save user ID
                    await saveUserId(user.id)
                }
            } catch {
                await updateError("Failed to load user data: \(error.localizedDescription)")
            }
            
            await updateLoadingState(false)
        }
    }
    
    private func createNewUser(id: String = UUID().uuidString) async throws -> User {
        // Create new user
        let now = Date()
        let newUser = User(
            id: id,
            gender: .male, // Default
            weight: 160, // Default
            age: 25, // Default
            hasAcceptedDisclaimer: false,
            createdAt: now,
            updatedAt: now
        )
        
        return try await userService.createUser(user: newUser)
    }
    
    func updateUserProfile(name: String? = nil, gender: Gender? = nil, weight: Double? = nil, age: Int? = nil) async throws {
        isLoading = true
        error = nil
        
        do {
            let updatedUser = try await userService.updateUserProfile(
                userId: currentUser.id,
                name: name,
                gender: gender,
                weight: weight,
                age: age
            )
            
            await updateUser(updatedUser)
        } catch {
            await updateError("Failed to update profile: \(error.localizedDescription)")
            throw error
        }
        
        await updateLoadingState(false)
    }
    
    func acceptDisclaimer() async throws {
        isLoading = true
        error = nil
        
        do {
            let updatedUser = try await userService.acceptDisclaimer(userId: currentUser.id)
            await updateUser(updatedUser)
            
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasAcceptedDisclaimer)
        } catch {
            await updateError("Failed to accept disclaimer: \(error.localizedDescription)")
            throw error
        }
        
        await updateLoadingState(false)
    }
    
    func addEmergencyContact(contactId: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let updatedUser = try await userService.addEmergencyContact(
                userId: currentUser.id,
                contactId: contactId
            )
            
            await updateUser(updatedUser)
        } catch {
            await updateError("Failed to add emergency contact: \(error.localizedDescription)")
            throw error
        }
        
        await updateLoadingState(false)
    }
    
    func removeEmergencyContact(contactId: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let updatedUser = try await userService.removeEmergencyContact(
                userId: currentUser.id,
                contactId: contactId
            )
            
            await updateUser(updatedUser)
        } catch {
            await updateError("Failed to remove emergency contact: \(error.localizedDescription)")
            throw error
        }
        
        await updateLoadingState(false)
    }
    
    func signOut() async {
        isLoading = true
        error = nil
        
        // Clear user data
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentUserId)
        
        // Reset user
        await updateUser(User.example)
        
        await updateLoadingState(false)
        
        // Load a new user
        loadUser()
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func updateUser(_ user: User) {
        self.currentUser = user
        self.hasAcceptedDisclaimer = user.hasAcceptedDisclaimer
        self.isFirstLaunch = user.name == nil
    }
    
    @MainActor
    private func updateLoadingState(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    @MainActor
    private func updateError(_ error: String) {
        self.error = error
    }
    
    @MainActor
    private func saveUserId(_ userId: String) {
        UserDefaults.standard.set(userId, forKey: Constants.UserDefaultsKeys.currentUserId)
    }
}
