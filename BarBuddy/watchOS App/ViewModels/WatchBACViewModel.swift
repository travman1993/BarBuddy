//
//  WatchBACViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/11/25.
//

import Foundation
import Combine

class WatchBACViewModel: ObservableObject {
    private let storageService = StorageService()
    
    @Published var currentBAC: BACEstimate = BACEstimate.empty()
    @Published var isCalculating = false
    @Published var error: String?
    
    // Timer for auto-refreshing BAC
    private var refreshTimer: Timer?
    
    init() {
        loadSavedBAC()
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    private func loadSavedBAC() {
        Task {
            do {
                if let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId),
                   let bacEstimate = try await storageService.getBAC(userId: userId) {
                    await MainActor.run {
                        self.currentBAC = bacEstimate
                    }
                }
            } catch {
                print("Error loading saved BAC: \(error)")
            }
        }
    }
    
    private func setupRefreshTimer() {
        // Update BAC calculation every 15 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshBAC()
            }
        }
    }
    
    func refreshBAC() async {
        await MainActor.run {
            isCalculating = true
            error = nil
        }
        
        do {
            // Get current user and drinks from storage
            guard let userId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUserId),
                  let user = try await storageService.getUser(id: userId) else {
                await MainActor.run {
                    error = "No user data found"
                    isCalculating = false
                }
                return
            }
            
            // Get recent drinks (past 24 hours)
            let drinks = try await storageService.getDrinksInTimeRange(
                userId: userId,
                start: Date().addingTimeInterval(-24 * 60 * 60),
                end: Date()
            )
            
            // Calculate BAC
            let bacEstimate = BACCalculator.calculateBAC(user: user, drinks: drinks)
            
            // Save BAC estimate
            try await storageService.saveBAC(bacEstimate, userId: userId)
            
            // Update UI
            await MainActor.run {
                currentBAC = bacEstimate
                isCalculating = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to calculate BAC: \(error.localizedDescription)"
                isCalculating = false
            }
        }
    }
    
    // Get contributing drinks to current BAC
    func getContributingDrinks(userId: String) async -> [Drink] {
        do {
            if currentBAC.drinkIds.isEmpty {
                return []
            }
            
            // Get all drinks from last 24 hours
            let drinks = try await storageService.getDrinksInTimeRange(
                userId: userId,
                start: Date().addingTimeInterval(-24 * 60 * 60),
                end: Date()
            )
            
            // Filter to only drinks that are contributing to current BAC
            return drinks.filter { currentBAC.drinkIds.contains($0.id) }
        } catch {
            return []
        }
    }
}
