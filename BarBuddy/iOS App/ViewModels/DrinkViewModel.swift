import Foundation
import Combine

class DrinkViewModel: ObservableObject {
    private let drinkService = DrinkService()
    private let notificationService = NotificationService()
    
    @Published var recentDrinks: [Drink] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadRecentDrinks(userId: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let now = Date()
            let yesterday = now.addingTimeInterval(-24 * 60 * 60)
            
            let drinks = try await drinkService.getDrinksInRange(
                userId: userId,
                start: yesterday,
                end: now
            )
            
            await MainActor.run {
                self.recentDrinks = drinks.sorted { $0.timestamp > $1.timestamp }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load drinks: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func addDrink(
        userId: String,
        type: DrinkType,
        name: String? = nil,
        alcoholPercentage: Double,
        amount: Double,
        location: String? = nil,
        notes: String? = nil
    ) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let drink = Drink(
                id: UUID().uuidString,
                userId: userId,
                type: type,
                name: name,
                alcoholPercentage: alcoholPercentage,
                amount: amount,
                timestamp: Date(),
                location: location,
                notes: notes
            )
            
            let savedDrink = try await drinkService.addDrink(drink: drink)
            
            // Log drink added
            Analytics.shared.logDrinkAdded(
                type: savedDrink.type,
                standardDrinks: savedDrink.standardDrinks
            )
            
            // Schedule check-in reminder
            notificationService.scheduleCheckInReminder(drinkTime: savedDrink.timestamp)
            
            // Schedule hydration reminder
            notificationService.scheduleHydrationReminder()
            
            // Reload recent drinks
            await loadRecentDrinks(userId: userId)
        } catch {
            await MainActor.run {
                self.error = "Failed to add drink: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func addStandardDrink(
        userId: String,
        type: DrinkType,
        location: String? = nil
    ) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let savedDrink = try await drinkService.addStandardDrink(
                userId: userId,
                type: type,
                location: location
            )
            
            // Log drink added
            Analytics.shared.logDrinkAdded(
                type: savedDrink.type,
                standardDrinks: savedDrink.standardDrinks
            )
            
            // Schedule check-in reminder
            notificationService.scheduleCheckInReminder(drinkTime: savedDrink.timestamp)
            
            // Schedule hydration reminder
            notificationService.scheduleHydrationReminder()
            
            // Reload recent drinks
            await loadRecentDrinks(userId: userId)
        } catch {
            await MainActor.run {
                self.error = "Failed to add standard drink: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func deleteDrink(id: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await drinkService.deleteDrink(id: id)
            
            // Update local state
            await MainActor.run {
                recentDrinks.removeAll { $0.id == id }
                isLoading = false
            }
            
            // Log event
            Analytics.shared.logEvent(.drinkDeleted)
        } catch {
            await MainActor.run {
                self.error = "Failed to delete drink: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func getContributingDrinks(_ bacEstimate: BACEstimate) -> [Drink] {
        return recentDrinks.filter { bacEstimate.drinkIds.contains($0.id) }
    }
}
