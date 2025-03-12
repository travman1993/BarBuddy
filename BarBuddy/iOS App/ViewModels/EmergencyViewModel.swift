import Foundation
import Combine

class EmergencyViewModel: ObservableObject {
    private let emergencyService = EmergencyService()
    private let locationService = LocationService()
    
    @Published var contacts: [EmergencyContact] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadContacts(userId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let loadedContacts = try await emergencyService.getUserContacts(userId: userId)
            
            await MainActor.run {
                contacts = loadedContacts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load contacts: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func addContact(
        userId: String,
        name: String,
        phoneNumber: String,
        isPrimary: Bool = false,
        enableAutoCheckIn: Bool = true,
        enableEmergencyAlerts: Bool = true
    ) async throws -> EmergencyContact {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let contact = EmergencyContact(
                userId: userId,
                name: name,
                phoneNumber: phoneNumber,
                isPrimary: isPrimary,
                enableAutoCheckIn: enableAutoCheckIn,
                enableEmergencyAlerts: enableEmergencyAlerts
            )
            
            let savedContact = try await emergencyService.addContact(contact: contact)
            
            // Log event
            Analytics.shared.logEvent(.contactAdded)
            
            // Reload contacts
            await loadContacts(userId: userId)
            
            return savedContact
        } catch {
            await MainActor.run {
                self.error = "Failed to add contact: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func updateContact(contact: EmergencyContact) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            _ = try await emergencyService.updateContact(contact: contact)
            
            // Reload contacts
            await loadContacts(userId: contact.userId)
        } catch {
            await MainActor.run {
                self.error = "Failed to update contact: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func deleteContact(id: String, userId: String) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await emergencyService.deleteContact(id: id)
            
            // Log event
            Analytics.shared.logEvent(.contactDeleted)
            
            // Reload contacts
            await loadContacts(userId: userId)
        } catch {
            await MainActor.run {
                self.error = "Failed to delete contact: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func setPrimaryContact(contactId: String, userId: String) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await emergencyService.setPrimaryContact(contactId: contactId, userId: userId)
            
            // Reload contacts
            await loadContacts(userId: userId)
        } catch {
            await MainActor.run {
                self.error = "Failed to set primary contact: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func sendEmergencyAlert(userId: String, userName: String) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Get current location if available
            var locationString: String? = nil
            
            do {
                let location = try await getCurrentLocation()
                locationString = location
            } catch {
                // Continue without location if it can't be obtained
                print("Could not get location for emergency alert: \(error)")
            }
            
            try await emergencyService.sendEmergencyAlert(
                userId: userId,
                userName: userName,
                location: locationString
            )
            
            // Log event
            Analytics.shared.logEvent(.emergencyAlertSent)
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to send emergency alert: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func sendCheckInMessage(userId: String, userName: String, onlyPrimary: Bool = false) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Get current location if available
            var locationString: String? = nil
            
            do {
                let location = try await getCurrentLocation()
                locationString = location
            } catch {
                // Continue without location if it can't be obtained
                print("Could not get location for check-in: \(error)")
            }
            
            try await emergencyService.sendCheckInMessage(
                userId: userId,
                userName: userName,
                location: locationString,
                onlyPrimary: onlyPrimary
            )
            
            // Log event
            Analytics.shared.logEvent(.checkInSent)
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to send check-in message: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    private func getCurrentLocation() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            locationService.getCurrentLocationAddress { result in
                switch result {
                case .success(let address):
                    continuation.resume(returning: address)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
