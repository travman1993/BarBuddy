import 'package:flutter_test/flutter_test.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/services/bac_calculator.dart';

void main() {
  group('BACCalculator Tests', () {
    late User maleUser;
    late User femaleUser;
    
    setUp(() {
      // Set up test users
      final now = DateTime.now();
      
      maleUser = User(
        id: 'test_male',
        gender: Gender.male,
        weight: 180, // 180 lbs
        age: 30,
        hasAcceptedDisclaimer: true,
        createdAt: now,
        updatedAt: now,
      );
      
      femaleUser = User(
        id: 'test_female',
        gender: Gender.female,
        weight: 140, // 140 lbs
        age: 30,
        hasAcceptedDisclaimer: true,
        createdAt: now,
        updatedAt: now,
      );
    });
    
    test('Empty drinks list should return zero BAC', () {
      final result = BACCalculator.calculateBAC(maleUser, []);
      
      expect(result.bac, equals(0.0));
      expect(result.drinkIds.isEmpty, isTrue);
    });
    
    test('Calculate BAC for male with one beer', () {
      final now = DateTime.now();
      
      final beer = Drink(
        id: 'beer1',
        userId: maleUser.id,
        type: DrinkType.beer,
        alcoholPercentage: 5.0,
        amount: 12.0, // 12 oz
        timestamp: now,
      );
      
      final result = BACCalculator.calculateBAC(maleUser, [beer]);
      
      // Expected BAC for a 180 lb male drinking one 12 oz beer with 5% ABV
      // should be approximately 0.023
      expect(result.bac, closeTo(0.023, 0.005));
      expect(result.drinkIds.length, equals(1));
      expect(result.drinkIds.contains('beer1'), isTrue);
    });
    
    test('Calculate BAC for female with one glass of wine', () {
      final now = DateTime.now();
      
      final wine = Drink(
        id: 'wine1',
        userId: femaleUser.id,
        type: DrinkType.wine,
        alcoholPercentage: 12.0,
        amount: 5.0, // 5 oz
        timestamp: now,
      );
      
      final result = BACCalculator.calculateBAC(femaleUser, [wine]);
      
      // Expected BAC for a 140 lb female drinking one 5 oz glass of wine with 12% ABV
      // should be approximately 0.032
      expect(result.bac, closeTo(0.032, 0.005));
      expect(result.drinkIds.length, equals(1));
      expect(result.drinkIds.contains('wine1'), isTrue);
    });
    
    test('Calculate BAC for male with multiple drinks', () {
      final now = DateTime.now();
      
      final drinks = [
        Drink(
          id: 'beer1',
          userId: maleUser.id,
          type: DrinkType.beer,
          alcoholPercentage: 5.0,
          amount: 12.0,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        Drink(
          id: 'beer2',
          userId: maleUser.id,
          type: DrinkType.beer,
          alcoholPercentage: 5.0,
          amount: 12.0,
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
        Drink(
          id: 'shot1',
          userId: maleUser.id,
          type: DrinkType.liquor,
          alcoholPercentage: 40.0,
          amount: 1.5,
          timestamp: now.subtract(const Duration(minutes: 30)),
        ),
      ];
      
      final result = BACCalculator.calculateBAC(maleUser, drinks);
      
      // Expected BAC should account for metabolism over time
      // First beer (2 hours ago) has been partially metabolized
      // Second beer (1 hour ago) has been partially metabolized
      // Shot (30 min ago) has been minimally metabolized
      expect(result.bac, greaterThan(0.0));
      expect(result.drinkIds.length, equals(3)); // All drinks should contribute
    });
    
    test('Calculate BAC for drink consumed more than 24 hours ago', () {
      final now = DateTime.now();
      
      final oldDrink = Drink(
        id: 'old_drink',
        userId: maleUser.id,
        type: DrinkType.beer,
        alcoholPercentage: 5.0,
        amount: 12.0,
        timestamp: now.subtract(const Duration(hours: 25)), // 25 hours ago
      );
      
      final result = BACCalculator.calculateBAC(maleUser, [oldDrink]);
      
      // BAC should be 0 as drink is fully metabolized
      expect(result.bac, equals(0.0));
      expect(result.drinkIds.isEmpty, isTrue);
    });
    
    test('Calculate BAC for drink that is fully metabolized', () {
      final now = DateTime.now();
      
      // A small drink consumed long enough ago to be fully metabolized
      final smallOldDrink = Drink(
        id: 'small_old',
        userId: maleUser.id,
        type: DrinkType.beer,
        alcoholPercentage: 3.0,
        amount: 8.0,
        timestamp: now.subtract(const Duration(hours: 3)), // 3 hours ago
      );
      
      final result = BACCalculator.calculateBAC(maleUser, [smallOldDrink]);
      
      // Verify drink has been fully metabolized (BAC = 0)
      expect(result.bac, equals(0.0));
      expect(result.drinkIds.isEmpty, isTrue);
    });
    
    test('Predict BAC with additional drink', () {
      final now = DateTime.now();
      
      final existingDrink = Drink(
        id: 'existing_drink',
        userId: maleUser.id,
        type: DrinkType.beer,
        alcoholPercentage: 5.0,
        amount: 12.0,
        timestamp: now.subtract(const Duration(minutes: 30)),
      );
      
      final newDrink = Drink(
        id: 'new_drink',
        userId: maleUser.id,
        type: DrinkType.liquor,
        alcoholPercentage: 40.0,
        amount: 1.5,
        timestamp: now,
      );
      
      final currentBAC = BACCalculator.calculateBAC(maleUser, [existingDrink]);
      final predictedBAC = BACCalculator.predictBAC(maleUser, [existingDrink], newDrink);
      
      // Predicted BAC should be higher than current BAC
      expect(predictedBAC.bac, greaterThan(currentBAC.bac));
      expect(predictedBAC.drinkIds.length, equals(2));
      expect(predictedBAC.drinkIds.contains('existing_drink'), isTrue);
      expect(predictedBAC.drinkIds.contains('new_drink'), isTrue);
    });
    
    test('Calculate standard drinks', () {
      final drinks = [
        Drink(
          id: 'beer',
          userId: 'user1',
          type: DrinkType.beer,
          alcoholPercentage: 5.0,
          amount: 12.0, // 1 standard drink
          timestamp: DateTime.now(),
        ),
        Drink(
          id: 'wine',
          userId: 'user1',
          type: DrinkType.wine,
          alcoholPercentage: 12.0,
          amount: 5.0, // 1 standard drink
          timestamp: DateTime.now(),
        ),
        Drink(
          id: 'shot',
          userId: 'user1',
          type: DrinkType.liquor,
          alcoholPercentage: 40.0,
          amount: 1.5, // 1 standard drink
          timestamp: DateTime.now(),
        ),
      ];
      
      final totalStandardDrinks = BACCalculator.calculateStandardDrinks(drinks);
      
      // Each drink is approximately 1 standard drink, so total should be 3
      expect(totalStandardDrinks, closeTo(3.0, 0.1));
    });
    
    test('Get risk level based on BAC', () {
      expect(BACCalculator.getRiskLevel(0.02), equals('Minimal Risk'));
      expect(BACCalculator.getRiskLevel(0.06), equals('Low Risk'));
      expect(BACCalculator.getRiskLevel(0.10), equals('Medium Risk'));
      expect(BACCalculator.getRiskLevel(0.20), equals('High Risk'));
    });
    
    test('Get possible effects based on BAC', () {
      final lowEffects = BACCalculator.getPossibleEffects(0.02);
      final moderateEffects = BACCalculator.getPossibleEffects(0.08);
      final highEffects = BACCalculator.getPossibleEffects(0.20);
      
      expect(lowEffects.isNotEmpty, isTrue);
      expect(moderateEffects.isNotEmpty, isTrue);
      expect(highEffects.isNotEmpty, isTrue);
      
      // Different BAC levels should have different effects
      expect(lowEffects.length, lessThan(moderateEffects.length));
      expect(moderateEffects.length, lessThan(highEffects.length));
    });
  });
}