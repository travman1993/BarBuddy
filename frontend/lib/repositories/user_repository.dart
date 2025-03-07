import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/services/firebase_service.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final String _collection = 'users';
  
  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firebaseService.firestore
          .collection(_collection)
          .doc(userId)
          .get();
      
      if (docSnapshot.exists) {
        return User.fromMap(docSnapshot.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }
  
  // Create new user
  Future<User> createUser(User user) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(user.id)
          .set(user.toMap());
      
      return user;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }
  
  // Update user
  Future<User> updateUser(User user) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toMap());
      
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }
  
  // Update specific user fields
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(userId)
          .update(fields);
    } catch (e) {
      debugPrint('Error updating user fields: $e');
      rethrow;
    }
  }
  
  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }
  
  // Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final docSnapshot = await _firebaseService.firestore
          .collection(_collection)
          .doc(userId)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      rethrow;
    }
  }
  
  // Get or create user
  Future<User> getOrCreateUser(String userId, {Gender? gender, double? weight, int? age}) async {
    try {
      // Check if user exists
      final existingUser = await getUserById(userId);
      
      if (existingUser != null) {
        return existingUser;
      }
      
      // Create new user
      final now = DateTime.now();
      final newUser = User(
        id: userId,
        gender: gender ?? Gender.male, // Default, will be updated during onboarding
        weight: weight ?? 160, // Default, will be updated during onboarding
        age: age ?? 25, // Default, will be updated during onboarding
        hasAcceptedDisclaimer: false,
        createdAt: now,
        updatedAt: now,
      );
      
      return await createUser(newUser);
    } catch (e) {
      debugPrint('Error in getOrCreateUser: $e');
      rethrow;
    }
  }
}