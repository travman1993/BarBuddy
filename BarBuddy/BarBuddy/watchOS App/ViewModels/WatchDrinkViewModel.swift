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
    
    @Published var isLoading = false
    @Published var error: String?
    
    func addStandardDrink(
        userId: String,
        type: DrinkType
    ) async throws {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            try await drinkService.addStandardDrink(
                userId: userId,
                type: type
            )
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to add standard drink: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
}
