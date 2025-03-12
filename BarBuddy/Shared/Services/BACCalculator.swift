import Foundation

class BACCalculator {
    // Widmark formula constants
    private static let metabolismRate: Double = 0.015 // Average alcohol metabolism rate per hour
    
    // Calculate BAC using the Widmark formula
    static func calculateBAC(user: User, drinks: [Drink]) -> BACEstimate {
        if drinks.isEmpty {
            return BACEstimate.empty()
        }
        
        // Sort drinks by timestamp (oldest first)
        let sortedDrinks = drinks.sorted { $0.timestamp < $1.timestamp }
        
        // Current time for calculations
        let now = Date()
        
        // Total alcohol consumed in ounces
        var totalAlcoholOunces = 0.0
        
        // Keep track of drink IDs used in this calculation
        var drinkIds: [String] = []
        
        // Calculate total alcohol and keep track of time since first and last drink
        for drink in sortedDrinks {
            // Calculate pure alcohol content in this drink (in fluid ounces)
            let alcoholContent = drink.amount * (drink.alcoholPercentage / 100)
            
            // Calculate hours since this drink was consumed
            let hoursSinceDrink = now.timeIntervalSince(drink.timestamp) / 3600.0
            
            // Only include drinks that still contribute alcohol
            if hoursSinceDrink <= (alcoholContent / metabolismRate) {
                // Subtract already metabolized alcohol
                let remainingAlcohol = alcoholContent - (metabolismRate * hoursSinceDrink)
                
                // Add remaining alcohol to total if positive
                if remainingAlcohol > 0 {
                    totalAlcoholOunces += remainingAlcohol
                    drinkIds.append(drink.id)
                }
            }
        }
        
        // If no remaining alcohol, return zero BAC
        if totalAlcoholOunces <= 0 || drinkIds.isEmpty {
            return BACEstimate.empty()
        }
        
        // Calculate BAC using Widmark formula
        // BAC = (alcohol in grams / (body weight in grams * body water constant)) * 100
        // Convert alcohol ounces to grams (1 oz = 29.57 grams)
        let alcoholGrams = totalAlcoholOunces * 29.57 * 0.79 // 0.79 = density of ethanol
        
        // Convert weight from pounds to grams
        let weightGrams = user.weight * 453.592
        
        // Calculate BAC percentage
        let bac = (alcoholGrams / (weightGrams * user.gender.bodyWaterConstant)) * 100
        
        // Round to 3 decimal places
        let roundedBAC = (bac * 1000).rounded() / 1000
        
        // Calculate time until legal BAC and sober
        var legalTime = now
        var soberTime = now
        
        if roundedBAC > 0 {
            // Hours until BAC reaches zero (complete sobriety)
            let hoursToSober = roundedBAC / metabolismRate
            
            // Hours until BAC reaches legal limit
            let hoursToLegal = (roundedBAC > Constants.BAC.legalLimit)
                ? (roundedBAC - Constants.BAC.legalLimit) / metabolismRate
                : 0
            
            // Calculate specific times
            soberTime = now.addingTimeInterval(hoursToSober * 3600)
            legalTime = now.addingTimeInterval(hoursToLegal * 3600)
        }
        
        return BACEstimate(
            bac: roundedBAC,
            timestamp: now,
            soberTime: soberTime,
            legalTime: legalTime,
            drinkIds: drinkIds
        )
    }
    
    // Predict BAC after adding a new drink
    static func predictBAC(user: User, currentDrinks: [Drink], newDrink: Drink) -> BACEstimate {
        var allDrinks = currentDrinks
        allDrinks.append(newDrink)
        return calculateBAC(user: user, drinks: allDrinks)
    }
    
    // Calculate standard drinks from a list of drinks
    static func calculateStandardDrinks(drinks: [Drink]) -> Double {
        var total = 0.0
        for drink in drinks {
            total += drink.standardDrinks
        }
        return (total * 10).rounded() / 10 // Round to 1 decimal place
    }
    
    // Get possible effects of current BAC level
    static func getPossibleEffects(bac: Double) -> [String] {
        if bac >= 0.30 {
            return [
                "Severe impairment of all mental and physical functions",
                "Possible loss of consciousness",
                "Risk of alcohol poisoning",
                "Risk of life-threatening suppression of vital functions"
            ]
        } else if bac >= 0.20 {
            return [
                "Disorientation, confusion, dizziness",
                "Exaggerated emotional states",
                "Impaired sensation",
                "Possible nausea and vomiting",
                "Blackouts likely"
            ]
        } else if bac >= 0.15 {
            return [
                "Significant impairment of physical control",
                "Blurred vision",
                "Major impairment of balance",
                "Slurred speech",
                "Judgment and perception severely impaired"
            ]
        } else if bac >= 0.08 {
            return [
                "Legally intoxicated in most states",
                "Impaired coordination and balance",
                "Reduced reaction time",
                "Reduced ability to detect danger",
                "Judgment and self-control impaired"
            ]
        } else if bac >= 0.05 {
            return [
                "Reduced inhibitions",
                "Affected judgment",
                "Lowered alertness",
                "Impaired coordination begins",
                "Difficulty steering"
            ]
        } else if bac >= 0.02 {
            return [
                "Some loss of judgment",
                "Relaxation",
                "Slight body warmth",
                "Altered mood",
                "Mild impairment of reasoning and memory"
            ]
        } else {
            return [
                "Little to no impairment for most people",
                "Subtle effects possible"
            ]
        }
    }
}
