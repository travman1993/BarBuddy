import Foundation

struct StandardDrink {
    let name: String
    let description: String
    let alcoholPercentage: Double
    let amount: Double
    let iconName: String
    
    var standardDrinks: Double {
        return (amount * alcoholPercentage / 100) / 0.6
    }
}

struct DrinkConstants {
    // Standard drink sizes & alcohol content (US Standards)
    static let beer = StandardDrink(
        name: "Beer",
        description: "12 oz of regular beer (5% alcohol)",
        alcoholPercentage: 5.0,
        amount: 12.0,
        iconName: "mug.fill"
    )
    
    static let wine = StandardDrink(
        name: "Wine",
        description: "5 oz of wine (12% alcohol)",
        alcoholPercentage: 12.0,
        amount: 5.0,
        iconName: "wineglass.fill"
    )
    
    static let liquor = StandardDrink(
        name: "Liquor",
        description: "1.5 oz of 80 proof liquor (40% alcohol)",
        alcoholPercentage: 40.0,
        amount: 1.5,
        iconName: "drop.fill"
    )
    
    static let cocktail = StandardDrink(
        name: "Cocktail",
        description: "Varies based on ingredients",
        alcoholPercentage: 15.0,
        amount: 8.0,
        iconName: "wineglass"
    )
    
    static let allDrinks: [DrinkType: StandardDrink] = [
        .beer: beer,
        .wine: wine,
        .liquor: liquor,
        .cocktail: cocktail
    ]
}
