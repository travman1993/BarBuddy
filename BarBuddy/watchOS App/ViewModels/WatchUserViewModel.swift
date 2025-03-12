//
//  WatchUserViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

// WatchUserViewModel.swift
import Foundation
import WatchKit
import Combine

class WatchUserViewModel: ObservableObject {
    private let userService = UserService()
    private let emergencyService = EmergencyService()
    private let storageService = StorageService()
    
    @Published var currentUser: User = User.example
    @Published var isLoading = false
    @Published var error: String?
    
    init() {
        loadUser()
    }
    
    private func loadUser() {
        isLoading = true
        
        Task {
            do {
                if let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId) {
                    if let user = try await userService.getUser(id: userId) {
                        await MainActor.run {
                            self.currentUser = user
                            self.isLoading = false
                        }
                    } else {
                        // Create a new user if not found
                        let user = try await createNewUser(id: userId)
                        await MainActor.run {
                            self.currentUser = user
                            self.isLoading = false
                        }
                    }
                } else {
                    // Create a new user for first launch
                    let user = try await createNewUser()
                    await MainActor.run {
                        self.currentUser = user
                        self.isLoading = false
                    }
                    
                    // Save user ID
                    UserDefaults.standard.set(user.id, forKey: Constants.UserDefaultsKeys.currentUserId)
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load user data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
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
    
    func sendEmergencyAlert() async throws {
        try await emergencyService.sendEmergencyAlert(
            userId: currentUser.id,
            userName: currentUser.name ?? "User"
        )
    }
    
    func sendCheckIn() async throws {
        try await emergencyService.sendCheckInMessage(
            userId: currentUser.id,
            userName: currentUser.name ?? "User"
        )
    }
    
    func synchronizeData() async {
        // In a real app, this would sync data with the iPhone app
        isLoading = true
        
        // Refresh user data from storage
        do {
            if let user = try await userService.getUser(id: currentUser.id) {
                await MainActor.run {
                    self.currentUser = user
                }
            }
        } catch {
            print("Error refreshing user data: \(error)")
        }
        
        // Simulate additional sync operations
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Get emergency contacts
    func getEmergencyContacts() async -> [EmergencyContact] {
        do {
            return try await emergencyService.getUserContacts(userId: currentUser.id)
        } catch {
            return []
        }
    }
    
    // Get primary emergency contact
    func getPrimaryEmergencyContact() async -> EmergencyContact? {
        do {
            return try await emergencyService.getPrimaryContact(userId: currentUser.id)
        } catch {
            return nil
        }
    }
}
