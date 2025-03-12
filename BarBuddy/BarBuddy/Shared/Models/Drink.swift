import Foundation

enum DrinkType: String, Codable, CaseIterable, Identifiable {
    case beer
    case wine
    case liquor
    case cocktail
    case custom
    
    var id: String { self.rawValue }
    
    var defaultName: String {
        switch self {
        case .beer:
            return "Beer"
        case .wine:
            return "Wine"
        case .liquor:
            return "Liquor"
        case .cocktail:
            return "Cocktail"
        case .custom:
            return "Custom Drink"
        }
    }
    
    var defaultAlcoholPercentage: Double {
        switch self {
        case .beer:
            return 5.0
        case .wine:
            return 12.0
        case .liquor:
            return 40.0
        case .cocktail:
            return 15.0
        case .custom:
            return 5.0
        }
    }
    
    var defaultAmount: Double {
        switch self {
        case .beer:
            return 12.0 // 12 oz
        case .wine:
            return 5.0  // 5 oz
        case .liquor:
            return 1.5  // 1.5 oz
        case .cocktail:
            return 8.0  // 8 oz
        case .custom:
            return 8.0  // 8 oz
        }
    }
    
    var systemIconName: String {
        switch self {
        case .beer:
            return "mug.fill"
        case .wine:
            return "wineglass.fill"
        case .liquor:
            return "drop.fill"
        case .cocktail:
            return "wineglass"
        case .custom:
            return "cup.and.saucer.fill"
        }
    }
}

struct Drink: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var userId: String
    var type: DrinkType
    var name: String?
    var alcoholPercentage: Double
    var amount: Double // in fluid ounces
    var timestamp: Date = Date()
    var location: String?
    var notes: String?
    
    // Standard drink calculation (1 standard drink = 0.6 oz of pure alcohol)
    var standardDrinks: Double {
        let pureAlcoholOunces = amount * (alcoholPercentage / 100)
        return pureAlcoholOunces / 0.6
    }
    
    // Display name for UI
    var displayName: String {
        if let customName = name, !customName.isEmpty {
            return customName
        }
        return "\(type.defaultName) (\(String(format: "%.1f", alcoholPercentage))%)"
    }
    
    // Example drink for previews
    static func example(type: DrinkType = .beer) -> Drink {
        Drink(
            userId: "exampleUser",
            type: type,
            alcoholPercentage: type.defaultAlcoholPercentage,
            amount: type.defaultAmount
        )
    }
}
