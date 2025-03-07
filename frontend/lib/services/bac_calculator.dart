import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/utils/constants.dart';

class BACCalculator {
  // Calculate BAC using the Widmark formula
  static BACEstimate calculateBAC(User user, List<Drink> drinks) {
    if (drinks.isEmpty) {
      return BACEstimate.empty();
    }
    
    // Sort drinks by timestamp (oldest first)
    drinks.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Current time for calculations
    final now = DateTime.now();
    
    // Total alcohol consumed in ounces
    double totalAlcoholOunces = 0.0;
    
    // Keep track of drink IDs used in this calculation
    List<String> drinkIds = [];
    
    // Calculate total alcohol and keep track of time since first and last drink
    DateTime firstDrinkTime = drinks.first.timestamp;
    DateTime lastDrinkTime = drinks.last.timestamp;
    
    for (var drink in drinks) {
      // Calculate pure alcohol content in this drink (in fluid ounces)
      double alcoholContent = drink.amount * (drink.alcoholPercentage / 100);
      
      // Calculate hours since this drink was consumed
      double hoursSinceDrink = now.difference(drink.timestamp).inMinutes / 60.0;
      
      // Only include drinks from the last 24 hours that still contribute alcohol
      if (hoursSinceDrink <= (alcoholContent / kMetabolismRate)) {
        // Subtract already metabolized alcohol
        double remainingAlcohol = alcoholContent - (kMetabolismRate * hoursSinceDrink);
        
        // Add remaining alcohol to total if positive
        if (remainingAlcohol > 0) {
          totalAlcoholOunces += remainingAlcohol;
          drinkIds.add(drink.id);
        }
      }
    }
    
    // If no remaining alcohol, return zero BAC
    if (totalAlcoholOunces <= 0 || drinkIds.isEmpty) {
      return BACEstimate.empty();
    }
    
    // Calculate BAC using Widmark formula
    // BAC = (alcohol in grams / (body weight in grams * body water constant)) * 100
    // Convert alcohol ounces to grams (1 oz = 29.57 grams)
    double alcoholGrams = totalAlcoholOunces * 29.57 * 0.79; // 0.79 = density of ethanol
    
    // Convert weight from pounds to grams
    double weightGrams = user.weight * 453.592;
    
    // Calculate BAC percentage
    double bac = (alcoholGrams / (weightGrams * user.bodyWaterConstant)) * 100;
    
    // Round to 3 decimal places
    bac = double.parse(bac.toStringAsFixed(3));
    
    // Calculate time until legal BAC and sober
    DateTime legalTime = now;
    DateTime soberTime = now;
    
    if (bac > 0) {
      // Hours until BAC reaches zero (complete sobriety)
      double hoursToSober = bac / kMetabolismRate;
      
      // Hours until BAC reaches legal limit
      double hoursToLegal = (bac > kLegalDrivingLimit) 
          ? (bac - kLegalDrivingLimit) / kMetabolismRate 
          : 0;
      
      // Calculate specific times
      soberTime = now.add(Duration(minutes: (hoursToSober * 60).round()));
      legalTime = now.add(Duration(minutes: (hoursToLegal * 60).round()));
    }
    
    return BACEstimate(
      bac: bac,
      timestamp: now,
      soberTime: soberTime,
      legalTime: legalTime,
      drinkIds: drinkIds,
    );
  }
  
  // Predict BAC after adding a new drink
  static BACEstimate predictBAC(User user, List<Drink> currentDrinks, Drink newDrink) {
    List<Drink> allDrinks = List.from(currentDrinks);
    allDrinks.add(newDrink);
    return calculateBAC(user, allDrinks);
  }
  
  // Calculate standard drinks from a list of drinks
  static double calculateStandardDrinks(List<Drink> drinks) {
    double total = 0.0;
    for (var drink in drinks) {
      total += drink.standardDrinks;
    }
    return double.parse(total.toStringAsFixed(1));
  }
  
  // Get risk level description based on BAC
  static String getRiskLevel(double bac) {
    if (bac >= kHighBACThreshold) {
      return 'High Risk';
    } else if (bac >= kLegalDrivingLimit) {
      return 'Medium Risk';
    } else if (bac >= kCautionBACThreshold) {
      return 'Low Risk';
    } else {
      return 'Minimal Risk';
    }
  }
  
  // Get possible effects of current BAC level
  static List<String> getPossibleEffects(double bac) {
    if (bac >= 0.30) {
      return [
        'Severe impairment of all mental and physical functions',
        'Possible loss of consciousness',
        'Risk of alcohol poisoning',
        'Risk of life-threatening suppression of vital functions'
      ];
    } else if (bac >= 0.20) {
      return [
        'Disorientation, confusion, dizziness',
        'Exaggerated emotional states',
        'Impaired sensation',
        'Possible nausea and vomiting',
        'Blackouts likely'
      ];
    } else if (bac >= 0.15) {
      return [
        'Significant impairment of physical control',
        'Blurred vision',
        'Major impairment of balance',
        'Slurred speech',
        'Judgment and perception severely impaired'
      ];
    } else if (bac >= 0.08) {
      return [
        'Legally intoxicated in most states',
        'Impaired coordination and balance',
        'Reduced reaction time',
        'Reduced ability to detect danger',
        'Judgment and self-control impaired'
      ];
    } else if (bac >= 0.05) {
      return [
        'Reduced inhibitions',
        'Affected judgment',
        'Lowered alertness',
        'Impaired coordination begins',
        'Difficulty steering'
      ];
    } else if (bac >= 0.02) {
      return [
        'Some loss of judgment',
        'Relaxation',
        'Slight body warmth',
        'Altered mood',
        'Mild impairment of reasoning and memory'
      ];
    } else {
      return [
        'Little to no impairment for most people',
        'Subtle effects possible'
      ];
    }
  }
}