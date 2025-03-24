//
//  DrinkTrackerViewModel.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/24/25.

#if os(watchOS)
import Foundation
import Combine
import SwiftUI

class DrinkTrackerViewModel: ObservableObject {
    // Core drink tracker instance
    private var drinkTracker: DrinkTracker
    
    // Published properties that mirror the DrinkTracker properties
    @Published var drinks: [Drink] = []
    @Published var currentBAC: Double = 0.0
    @Published var timeUntilSober: TimeInterval = 0
    
    // Additional state properties
    @Published var isAddingDrink: Bool = false
    @Published var isDrinkingSession: Bool = false
    @Published var sessionStartTime: Date? = nil
    
    // Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    init(drinkTracker: DrinkTracker = DrinkTracker()) {
        self.drinkTracker = drinkTracker
        
        // Set up bindings
        setupBindings()
        refreshFromDrinkTracker()
    }
    
    private func setupBindings() {
        // Observe the DrinkTracker properties
        drinkTracker.objectWillChange
            .sink { [weak self] _ in
                self?.refreshFromDrinkTracker()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func refreshFromDrinkTracker() {
        drinks = drinkTracker.drinks
        currentBAC = drinkTracker.currentBAC
        timeUntilSober = drinkTracker.timeUntilSober
        
        // Check drinking session status
        checkForDrinkingSession()
    }
    
    // MARK: - Public Methods
    
    func addDrink(type: DrinkType, size: Double = 0, alcoholPercentage: Double = 0) {
        // Use default values if not provided
        let actualSize = size > 0 ? size : type.defaultSize
        let actualPercentage = alcoholPercentage > 0 ? alcoholPercentage : type.defaultAlcoholPercentage
        
        drinkTracker.addDrink(
            type: type,
            size: actualSize,
            alcoholPercentage: actualPercentage
        )
        
        // Update drinking session status
        if !isDrinkingSession {
            isDrinkingSession = true
            sessionStartTime = Date()
        }
    }
    
    func removeDrink(_ drink: Drink) {
        // On Watch, we don't really remove drinks directly
        // Instead, this would be done through synchronization with the phone
        WatchSessionManager.shared.requestBACUpdate()
    }
    
    // MARK: - Helper Methods
    
    private func checkForDrinkingSession() {
        let recentDrinks = drinks.filter {
            $0.timestamp.timeIntervalSinceNow > -6 * 3600 // Last 6 hours
        }
        
        if !recentDrinks.isEmpty && !isDrinkingSession {
            isDrinkingSession = true
            sessionStartTime = recentDrinks.min { $0.timestamp < $1.timestamp }?.timestamp
        } else if recentDrinks.isEmpty && isDrinkingSession {
            isDrinkingSession = false
            sessionStartTime = nil
        }
    }
    
    // MARK: - Utility Methods
    
    func getFormattedTimeUntilSober() -> String {
        let hours = Int(timeUntilSober) / 3600
        let minutes = (Int(timeUntilSober) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    func getSafetyStatus() -> SafetyStatus {
        if currentBAC < 0.04 {
            return .safe
        } else if currentBAC < 0.08 {
            return .borderline
        } else {
            return .unsafe
        }
    }
}
#endif
