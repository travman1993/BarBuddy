//
//  DrinkTrackerWatch.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 3/23/25.
//
import Foundation
import Combine

public class DrinkTracker: ObservableObject {
    // Lightweight version for Watch
    @Published public var drinks: [Drink] = []
    @Published public var currentBAC: Double = 0.0
    @Published public var timeUntilSober: TimeInterval = 0
    
    public init() {
        // Initial setup, primarily for receiving data from iPhone
    }
    
    // Method to update from iPhone data
    public func updateFromiPhone(drinks: [Drink], bac: Double, timeUntilSober: TimeInterval) {
        self.drinks = drinks
        self.currentBAC = bac
        self.timeUntilSober = timeUntilSober
    }
    
    // Minimal local drink addition (will sync with iPhone)
    public func addDrink(type: DrinkType, size: Double, alcoholPercentage: Double) {
        let newDrink = Drink(
            type: type,
            size: size,
            alcoholPercentage: alcoholPercentage,
            timestamp: Date()
        )
        
        // Send to iPhone for primary processing
        WatchSessionManager.shared.logDrink(type: type)
    }
}
