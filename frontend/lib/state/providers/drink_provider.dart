import 'package:flutter/material.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/models/bac_model.dart';
import 'package:barbuddy/services/drink_logger.dart';
import 'package:barbuddy/services/bac_calculator.dart';
import 'package:barbuddy/state/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class DrinkProvider extends ChangeNotifier {
  final DrinkLogger _drinkLogger = DrinkLogger();
  final Uuid _uuid = const Uuid();
  
  List<Drink> _recentDrinks = [];
  BACEstimate _currentBAC = BACEstimate.empty();
  bool _isLoading = false;
  
  // Getters
  List<Drink> get recentDrinks => _recentDrinks;
  BACEstimate get currentBAC => _currentBAC;
  bool get isLoading => _isLoading;
  
  // Load recent drinks (past 24 hours)
  Future<void> loadRecentDrinks() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Need to get user ID from context
      final BuildContext context = navigatorKey.currentContext!;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      _recentDrinks = await _drinkLogger.getRecentDrinks(userProvider.currentUser.id);
      
      // Calculate current BAC
      await recalculateBAC();
    } catch (e) {
      debugPrint('Error loading recent drinks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new drink
  Future<Drink> addDrink({
    required String userId,
    required DrinkType type,
    String? name,
    required double alcoholPercentage,
    required double amount,
    String? location,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newDrink = await _drinkLogger.logDrink(
        userId: userId,
        type: type,
        name: name,
        alcoholPercentage: alcoholPercentage,
        amount: amount,
        location: location,
        notes: notes,
      );
      
      // Add to local list and sort by timestamp
      _recentDrinks.add(newDrink);
      _recentDrinks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return newDrink;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a standard drink
  Future<Drink> addStandardDrink({
    required String userId,
    required DrinkType type,
    String? location,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final newDrink = await _drinkLogger.logStandardDrink(
        userId: userId,
        type: type,
        location: location,
      );
      
      // Add to local list and sort by timestamp
      _recentDrinks.add(newDrink);
      _recentDrinks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return newDrink;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a drink
  Future<void> deleteDrink(String drinkId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _drinkLogger.deleteDrink(drinkId);
      
      // Remove from local list
      _recentDrinks.removeWhere((drink) => drink.id == drinkId);
      
      // Recalculate BAC
      await recalculateBAC();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Recalculate BAC based on user and drinks
  Future<BACEstimate> recalculateBAC() async {
    try {
      final BuildContext context = navigatorKey.currentContext!;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      _currentBAC = BACCalculator.calculateBAC(
        userProvider.currentUser, 
        _recentDrinks,
      );
      
      notifyListeners();
      return _currentBAC;
    } catch (e) {
      debugPrint('Error calculating BAC: $e');
      return _currentBAC;
    }
  }
  
  // Get drinks that are contributing to current BAC
  List<Drink> getContributingDrinks(BACEstimate bacEstimate) {
    return _recentDrinks
        .where((drink) => bacEstimate.drinkIds.contains(drink.id))
        .toList();
  }
  
  // Calculate total standard drinks consumed in last 24 hours
  double getTotalStandardDrinks() {
    double total = 0.0;
    for (var drink in _recentDrinks) {
      total += drink.standardDrinks;
    }
    return double.parse(total.toStringAsFixed(1));
  }
  
  // Calculate total standard drinks by type in last 24 hours
  Map<DrinkType, double> getStandardDrinksByType() {
    final Map<DrinkType, double> result = {};
    
    for (var drink in _recentDrinks) {
      final currentValue = result[drink.type] ?? 0.0;
      result[drink.type] = currentValue + drink.standardDrinks;
    }
    
    // Round values
    result.forEach((key, value) {
      result[key] = double.parse(value.toStringAsFixed(1));
    });
    
    return result;
  }
  
  // Global navigator key for accessing context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}