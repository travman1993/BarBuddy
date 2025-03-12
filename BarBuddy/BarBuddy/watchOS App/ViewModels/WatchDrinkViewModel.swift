//
//  WatchDrinkViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import Combine

class WatchDrinkViewModel: ObservableObject {
    private let drinkService = DrinkService()
    
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
    
    func addStandardDrink(
        userId: String,
        type: DrinkType,
        location: String? = nil
    ) async throws {
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
            
            // Reload recent drinks
            await loadRecentDrinks(userId: userId)
            
            await MainActor.run {
                isLoading = false
            }
            
            return savedDrink
        } catch {
            await MainActor.run {
                self.error = "Failed to add standard drink: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func deleteDrink(id: String, userId: String) async throws {
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
        } catch {
            await MainActor.run {
                self.error = "Failed to delete drink: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
}
