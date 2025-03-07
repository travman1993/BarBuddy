import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/utils/constants.dart';

class DrinkLogger {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'drinks';
  final Uuid _uuid = const Uuid();
  
  // Add a new drink
  Future<Drink> logDrink({
    required String userId,
    required DrinkType type,
    String? name,
    required double alcoholPercentage,
    required double amount,
    String? location,
    String? notes,
  }) async {
    final String id = _uuid.v4();
    final DateTime timestamp = DateTime.now();
    
    final Drink drink = Drink(
      id: id,
      userId: userId,
      type: type,
      name: name,
      alcoholPercentage: alcoholPercentage,
      amount: amount,
      timestamp: timestamp,
      location: location,
      notes: notes,
    );
    
    await _firestore
        .collection(_collection)
        .doc(id)
        .set(drink.toMap());
    
    return drink;
  }
  
  // Log a standard drink quickly
  Future<Drink> logStandardDrink({
    required String userId,
    required DrinkType type,
    String? location,
  }) async {
    // Get default values for this drink type
    Map<String, dynamic> defaults = kStandardDrinks[type.toString().split('.').last] ?? 
        kStandardDrinks['Beer']!;
    
    return logDrink(
      userId: userId,
      type: type,
      alcoholPercentage: defaults['defaultAbv'],
      amount: defaults['standardOz'],
      location: location,
    );
  }
  
  // Update an existing drink
  Future<Drink> updateDrink(Drink drink) async {
    await _firestore
        .collection(_collection)
        .doc(drink.id)
        .update(drink.toMap());
    
    return drink;
  }
  
  // Delete a drink
  Future<void> deleteDrink(String drinkId) async {
    await _firestore
        .collection(_collection)
        .doc(drinkId)
        .delete();
  }
  
  // Get all drinks for a user
  Future<List<Drink>> getUserDrinks(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Drink.fromMap(doc.data())).toList();
  }
  
  // Get drinks for a user within a specific time range
  Future<List<Drink>> getUserDrinksInRange(
    String userId, 
    DateTime start, 
    DateTime end
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Drink.fromMap(doc.data())).toList();
  }
  
  // Get drinks for the past 24 hours
  Future<List<Drink>> getRecentDrinks(String userId) async {
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(hours: 24));
    
    return getUserDrinksInRange(userId, yesterday, now);
  }
  
  // Get total number of drinks consumed in a time period
  Future<int> getDrinkCount(String userId, DateTime start, DateTime end) async {
    final drinks = await getUserDrinksInRange(userId, start, end);
    return drinks.length;
  }
  
  // Calculate total standard drinks in a time period
  Future<double> getStandardDrinkCount(
    String userId, 
    DateTime start, 
    DateTime end
  ) async {
    final drinks = await getUserDrinksInRange(userId, start, end);
    
    double total = 0.0;
    for (var drink in drinks) {
      total += drink.standardDrinks;
    }
    
    return double.parse(total.toStringAsFixed(1));
  }
  
  // Get stats about drinking patterns
  Future<Map<String, dynamic>> getUserDrinkingStats(String userId) async {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    
    // Get drinks for different time periods
    final List<Drink> today = await getUserDrinksInRange(
      userId, 
      todayStart, 
      now
    );
    
    final List<Drink> yesterday = await getUserDrinksInRange(
      userId, 
      yesterdayStart, 
      todayStart.subtract(const Duration(seconds: 1))
    );
    
    final List<Drink> pastWeek = await getUserDrinksInRange(
      userId, 
      oneWeekAgo, 
      now
    );
    
    final List<Drink> pastMonth = await getUserDrinksInRange(
      userId, 
      oneMonthAgo, 
      now
    );
    
    // Calculate standard drinks for each period
    double todayStandard = 0.0;
    double yesterdayStandard = 0.0;
    double weekStandard = 0.0;
    double monthStandard = 0.0;
    
    for (var drink in today) {
      todayStandard += drink.standardDrinks;
    }
    
    for (var drink in yesterday) {
      yesterdayStandard += drink.standardDrinks;
    }
    
    for (var drink in pastWeek) {
      weekStandard += drink.standardDrinks;
    }
    
    for (var drink in pastMonth) {
      monthStandard += drink.standardDrinks;
    }
    
    // Determine most common drink type in the past month
    Map<DrinkType, int> typeCounts = {};
    for (var drink in pastMonth) {
      typeCounts[drink.type] = (typeCounts[drink.type] ?? 0) + 1;
    }
    
    DrinkType? mostCommonType;
    int maxCount = 0;
    
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonType = type;
      }
    });
    
    return {
      'today': {
        'count': today.length,
        'standardDrinks': double.parse(todayStandard.toStringAsFixed(1)),
      },
      'yesterday': {
        'count': yesterday.length,
        'standardDrinks': double.parse(yesterdayStandard.toStringAsFixed(1)),
      },
      'pastWeek': {
        'count': pastWeek.length,
        'standardDrinks': double.parse(weekStandard.toStringAsFixed(1)),
        'dailyAverage': double.parse((weekStandard / 7).toStringAsFixed(1)),
      },
      'pastMonth': {
        'count': pastMonth.length,
        'standardDrinks': double.parse(monthStandard.toStringAsFixed(1)),
        'dailyAverage': double.parse((monthStandard / 30).toStringAsFixed(1)),
        'mostCommonType': mostCommonType?.toString().split('.').last ?? 'none',
      },
    };
  }
}