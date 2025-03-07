import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbuddy/models/drink_model.dart';
import 'package:barbuddy/services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DrinkRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final String _collection = 'drinks';
  final Uuid _uuid = const Uuid();
  
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
    try {
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
      
      await _firebaseService.firestore
          .collection(_collection)
          .doc(id)
          .set(drink.toMap());
      
      return drink;
    } catch (e) {
      debugPrint('Error adding drink: $e');
      rethrow;
    }
  }
  
  // Update a drink
  Future<Drink> updateDrink(Drink drink) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(drink.id)
          .update(drink.toMap());
      
      return drink;
    } catch (e) {
      debugPrint('Error updating drink: $e');
      rethrow;
    }
  }
  
  // Delete a drink
  Future<void> deleteDrink(String drinkId) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(drinkId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting drink: $e');
      rethrow;
    }
  }
  
  // Get a drink by ID
  Future<Drink?> getDrinkById(String drinkId) async {
    try {
      final docSnapshot = await _firebaseService.firestore
          .collection(_collection)
          .doc(drinkId)
          .get();
      
      if (docSnapshot.exists) {
        return Drink.fromMap(docSnapshot.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting drink: $e');
      rethrow;
    }
  }
  
  // Get all drinks for a user
  Future<List<Drink>> getUserDrinks(String userId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Drink.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user drinks: $e');
      rethrow;
    }
  }
  
  // Get drinks for a user within a time range
  Future<List<Drink>> getDrinksInTimeRange(
    String userId, 
    DateTime start, 
    DateTime end
  ) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Drink.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting drinks in time range: $e');
      rethrow;
    }
  }
  
  // Get recent drinks (last 24 hours)
  Future<List<Drink>> getRecentDrinks(String userId) async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    return getDrinksInTimeRange(userId, yesterday, now);
  }
  
  // Stream of user drinks for real-time updates
  Stream<List<Drink>> streamUserDrinks(String userId) {
    try {
      return _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Drink.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error streaming user drinks: $e');
      rethrow;
    }
  }
  
  // Stream of recent drinks for real-time updates
  Stream<List<Drink>> streamRecentDrinks(String userId) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));
    
    try {
      return _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Drink.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error streaming recent drinks: $e');
      rethrow;
    }
  }
}