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
        // Initial standard drink count should be 0
        XCTAssertEqual(drinkTracker.standardDrinkCount, 0.0, "Initial standard drink count should be 0")
        
        // Add a drink
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        
        // Standard drink count should now be greater than 0
        XCTAssertGreaterThan(drinkTracker.standardDrinkCount, 0.0, "Standard drink count should increase after adding a drink")
        
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
        
        // Standard drink count should now be 0 again
        XCTAssertEqual(drinkTracker.standardDrinkCount, 0.0, "Standard drink count should be 0 after removing all drinks")
    }
    
    func testStandardDrinkCalculation() {
        // Add a standard drink (1.5 oz of 40% liquor)
        drinkTracker.addDrink(type: .shot, size: 1.5, alcoholPercentage: 40.0)
        
        // Check standard drink count
        XCTAssertGreaterThanOrEqual(drinkTracker.standardDrinkCount, 0.5, "Standard drink count should be at least 0.5 for one shot")
        XCTAssertLessThanOrEqual(drinkTracker.standardDrinkCount, 1.5, "Standard drink count should be at most 1.5 for one shot")
        
        // Test standard drink count for female (could be slightly different)
        let femaleProfile = UserProfile(
            weight: 160.0,
            gender: .female,
            emergencyContacts: []
        )
        drinkTracker.updateUserProfile(femaleProfile)
        
        // Re-add the drink
        drinkTracker.clearDrinks()
        drinkTracker.addDrink(type: .shot, size: 1.5, alcoholPercentage: 40.0)
        
        // Verify standard drink calculation
        XCTAssertGreaterThan(drinkTracker.standardDrinkCount, 0.5, "Standard drink count should be consistent")
    }
    
    func testTimeUntilReset() {
        // Add multiple drinks
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        drinkTracker.addDrink(type: .beer, size: 12.0, alcoholPercentage: 5.0)
        
        // Time until reset should be greater than 0
        XCTAssertGreaterThan(drinkTracker.timeUntilReset, 0, "Time until reset should be greater than 0")
        
        // General estimate: Reset occurs at 4 AM
        let fourAMInSeconds: TimeInterval = 4 * 60 * 60
        XCTAssertLessThanOrEqual(drinkTracker.timeUntilReset, 24 * 60 * 60, "Time until reset should be within 24 hours")
    }
}
