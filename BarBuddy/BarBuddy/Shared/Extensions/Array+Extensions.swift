import Foundation

extension Array where Element: Equatable {
    // Remove first occurrence of an element
    mutating func removeFirstOccurrence(of element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
    
    // Check if array contains all elements in another array
    func containsAll<T: Equatable>(of array: [T]) -> Bool where Element == T {
        for item in array {
            if !contains(item) {
                return false
            }
        }
        return true
    }
}

extension Array where Element == Drink {
    // Calculate total standard drinks
    var totalStandardDrinks: Double {
        return reduce(0) { $0 + $1.standardDrinks }
    }
    
    // Filter drinks within the last N hours
    func inLastHours(_ hours: Int) -> [Drink] {
        let timeAgo = Date().addingTimeInterval(-Double(hours * 3600))
        return filter { $0.timestamp > timeAgo }
    }
    
    // Group drinks by date
    func groupedByDate() -> [Date: [Drink]] {
        let calendar = Calendar.current
        
        var groupedDrinks: [Date: [Drink]] = [:]
        
        for drink in self {
            let startOfDay = calendar.startOfDay(for: drink.timestamp)
            
            if groupedDrinks[startOfDay] != nil {
                groupedDrinks[startOfDay]?.append(drink)
            } else {
                groupedDrinks[startOfDay] = [drink]
            }
        }
        
        return groupedDrinks
    }
    
    // Group drinks by type
    func groupedByType() -> [DrinkType: [Drink]] {
        var groupedDrinks: [DrinkType: [Drink]] = [:]
        
        for drink in self {
            if groupedDrinks[drink.type] != nil {
                groupedDrinks[drink.type]?.append(drink)
            } else {
                groupedDrinks[drink.type] = [drink]
            }
        }
        
        return groupedDrinks
    }
    
    // Get most common drink type
    var mostCommonType: DrinkType? {
        let groupedByType = groupedByType()
        return groupedByType.max(by: { $0.value.count < $1.value.count })?.key
    }
}
