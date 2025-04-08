//
//  DrinkTrackerTests.swift
//  BarBuddy
//
//  Created by Travis Rodriguez on 4/7/25.
//
// File: BarBuddyTests/DrinkTrackerTests.swift
import XCTest
@testable import BarBuddy

final class DrinkTrackerTests: XCTestCase {
    var drinkTracker: DrinkTracker!
    
    override func setUp() {
        super.setUp()
        drinkTracker = DrinkTracker()
        
        // Set up a test profile
        let testProfile = UserProfile(
            weight: 160.0,
            gender: .male,
            emergencyContacts: []
        )
        drinkTracker.updateUserProfile(testProfile)
    }
    
    override func tearDown() {
        drinkTracker = nil
        super.tearDown()
    }
    
    func testAddDrink() {
        // Initial BAC should be 0
        XCTAssertEqual(drinkTracker.currentBAC, 0.0, "Initial BAC should be 0")
        
        // Add a drink
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        
        // BAC should now be greater than 0
        XCTAssertGreaterThan(drinkTracker.currentBAC, 0.0, "BAC should increase after adding a drink")
        
        // Drinks array should have one item
        XCTAssertEqual(drinkTracker.drinks.count, 1, "Drinks array should have one item")
    }
    
    func testRemoveDrink() {
        // Add a drink
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        let drink = drinkTracker.drinks.first!
        
        // Remove the drink
        drinkTracker.removeDrink(drink)
        
        // Drinks array should be empty
        XCTAssertEqual(drinkTracker.drinks.count, 0, "Drinks array should be empty after removing the drink")
        
        // BAC should now be 0 again
        XCTAssertEqual(drinkTracker.currentBAC, 0.0, "BAC should be 0 after removing all drinks")
    }
    
    func testBACCalculation() {
        // Add a standard drink (1.5 oz of 40% liquor)
        drinkTracker.addDrink(type: .shot, size: 1.5, alcoholPercentage: 40.0)
        
        // For a 160 lb male, one standard drink should result in approximately 0.02 - 0.025 BAC
        XCTAssertGreaterThanOrEqual(drinkTracker.currentBAC, 0.01, "BAC should be at least 0.01 for one standard drink")
        XCTAssertLessThanOrEqual(drinkTracker.currentBAC, 0.03, "BAC should be at most 0.03 for one standard drink")
        
        // Test BAC for female (should be higher with same drink)
        let femaleProfile = UserProfile(
            weight: 160.0,
            gender: .female,
            emergencyContacts: []
        )
        drinkTracker.updateUserProfile(femaleProfile)
        
        // Re-add the drink
        drinkTracker.clearDrinks()
        drinkTracker.addDrink(type: .shot, size: 1.5, alcoholPercentage: 40.0)
        
        // Female BAC should be higher than male BAC for same drink
        XCTAssertGreaterThan(drinkTracker.currentBAC, 0.02, "Female BAC should be higher than male BAC for same drink")
    }
    
    func testTimeUntilSober() {
        // Add multiple drinks
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        
        // Time until sober should be greater than 0
        XCTAssertGreaterThan(drinkTracker.timeUntilSober, 0, "Time until sober should be greater than 0")
        
        // General estimate: Each standard drink takes about 1 hour to process
        // Two beers are roughly 2 standard drinks, so time until sober should be roughly 2 hours
        let twoHoursInSeconds: TimeInterval = 2 * 60 * 60
        XCTAssertGreaterThanOrEqual(drinkTracker.timeUntilSober, twoHoursInSeconds * 0.7, "Time until sober should be roughly 2 hours for 2 beers")
        XCTAssertLessThanOrEqual(drinkTracker.timeUntilSober, twoHoursInSeconds * 1.3, "Time until sober should be roughly 2 hours for 2 beers")
    }
}
