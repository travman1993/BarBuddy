import Foundation

class DrinkService {
    private let storageService: StorageService
    
    init(storageService: StorageService = StorageService()) {
        self.storageService = storageService
    }
    
    // Save a new drink
    func addDrink(drink: Drink) async throws -> Drink {
        try await storageService.saveDrink(drink)
        return drink
    }
    
    // Save a standard drink quickly with default values
    func addStandardDrink(userId: String, type: DrinkType, location: String? = nil) async throws -> Drink {
        let drinkConstants = DrinkConstants.allDrinks[type]
        
        let drink = Drink(
            userId: userId,
            type: type,
            alcoholPercentage: type.defaultAlcoholPercentage,
            amount: type.defaultAmount,
            location: location
        )
        
        return try await addDrink(drink: drink)
    }
    
    // Update an existing drink
    func updateDrink(drink: Drink) async throws -> Drink {
        try await storageService.saveDrink(drink)
        return drink
    }
    
    // Delete a drink
    func deleteDrink(id: String) async throws {
        try await storageService.deleteDrink(id: id)
    }
    
    // Get a drink by ID
    func getDrink(id: String) async throws -> Drink? {
        try await storageService.getDrink(id: id)
    }
    
    // Get all drinks for a user
    func getUserDrinks(userId: String) async throws -> [Drink] {
        try await storageService.getUserDrinks(userId: userId)
    }
    
    // Get drinks for a time period
    func getDrinksInRange(userId: String, start: Date, end: Date) async throws -> [Drink] {
        try await storageService.getDrinksInTimeRange(userId: userId, start: start, end: end)
    }
    
    // Get recent drinks (past 24 hours)
    func getRecentDrinks(userId: String) async throws -> [Drink] {
        let now = Date()
        let yesterday = now.addingTimeInterval(-24 * 60 * 60)
        return try await getDrinksInRange(userId: userId, start: yesterday, end: now)
    }
    
    // Get drinking statistics for a user
    func getUserDrinkingStats(userId: String) async throws -> [String: Any] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!.startOfDay
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        
        let todayStart = now.startOfDay
        let yesterdayStart = yesterday
        
        // Get drinks for different time periods
        let today = try await getDrinksInRange(userId: userId, start: todayStart, end: now)
        let yesterdayDrinks = try await getDrinksInRange(userId: userId, start: yesterdayStart, end: todayStart)
        let pastWeek = try await getDrinksInRange(userId: userId, start: oneWeekAgo, end: now)
        let pastMonth = try await getDrinksInRange(userId: userId, start: oneMonthAgo, end: now)
        
        // Calculate standard drinks for each period
        let todayStandard = BACCalculator.calculateStandardDrinks(drinks: today)
        let yesterdayStandard = BACCalculator.calculateStandardDrinks(drinks: yesterdayDrinks)
        let weekStandard = BACCalculator.calculateStandardDrinks(drinks: pastWeek)
        let monthStandard = BACCalculator.calculateStandardDrinks(drinks: pastMonth)
        
        // Find most common drink type
        var typeCounts: [DrinkType: Int] = [:]
        for drink in pastMonth {
            typeCounts[drink.type, default: 0] += 1
        }
        
        let mostCommonType = typeCounts.max(by: { $0.value < $1.value })?.key
        
        return [
            "today": [
                "count": today.count,
                "standardDrinks": todayStandard
            ],
            "yesterday": [
                "count": yesterdayDrinks.count,
                "standardDrinks": yesterdayStandard
            ],
            "pastWeek": [
                "count": pastWeek.count,
                "standardDrinks": weekStandard,
                "dailyAverage": weekStandard / 7
            ],
            "pastMonth": [
                "count": pastMonth.count,
                "standardDrinks": monthStandard,
                "dailyAverage": monthStandard / 30,
                "mostCommonType": mostCommonType?.rawValue ?? "none"
            ]
        ]
    }
}
