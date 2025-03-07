import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:barbuddy/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';
  final Uuid _uuid = const Uuid();
  
  bool _isLoading = false;
  late User _currentUser;
  bool _isFirstTime = true;
  
  // Getters
  bool get isLoading => _isLoading;
  User get currentUser => _currentUser;
  bool get isFirstTime => _isFirstTime;
  
  // Constructor
  UserProvider() {
    _initializeUser();
  }
  
  // Initialize user from local storage or create a new one
  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        // User exists, fetch from Firestore
        final userDoc = await _firestore.collection(_collection).doc(userId).get();
        
        if (userDoc.exists) {
          _currentUser = User.fromMap(userDoc.data()!);
          _isFirstTime = false;
        } else {
          // User ID exists locally but not in Firestore (rare case)
          _createNewUser();
        }
      } else {
        // New user, create a new record
        _createNewUser();
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
      // Create a local user as fallback
      _createLocalUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a new user in Firestore
  Future<void> _createNewUser() async {
    final String id = _uuid.v4();
    final now = DateTime.now();
    
    // Create default user
    _currentUser = User(
      id: id,
      gender: Gender.male, // Default, will be updated during onboarding
      weight: 160, // Default, will be updated during onboarding
      age: 25, // Default, will be updated during onboarding
      hasAcceptedDisclaimer: false,
      createdAt: now,
      updatedAt: now,
    );
    
    // Save to Firestore
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .set(_currentUser.toMap());
      
      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', id);
      
      _isFirstTime = true;
    } catch (e) {
      debugPrint('Error creating new user: $e');
      // If Firestore fails, still keep the user in memory
    }
  }
  
  // Create a local user (when offline)
  void _createLocalUser() {
    final String id = _uuid.v4();
    final now = DateTime.now();
    
    _currentUser = User(
      id: id,
      gender: Gender.male,
      weight: 160,
      age: 25,
      hasAcceptedDisclaimer: false,
      createdAt: now,
      updatedAt: now,
    );
    
    _isFirstTime = true;
  }
  
  // Update user information
  Future<void> updateUser({
    String? name,
    Gender? gender,
    double? weight,
    int? age,
    bool? hasAcceptedDisclaimer,
    List<String>? emergencyContactIds,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Create updated user
      _currentUser = _currentUser.copyWith(
        name: name,
        gender: gender,
        weight: weight,
        age: age,
        hasAcceptedDisclaimer: hasAcceptedDisclaimer,
        emergencyContactIds: emergencyContactIds,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _firestore
          .collection(_collection)
          .doc(_currentUser.id)
          .update(_currentUser.toMap());
      
      // If this was the first update with disclaimer acceptance, update firstTime flag
      if (hasAcceptedDisclaimer == true) {
        _isFirstTime = false;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      // Keep the updated user in memory even if Firestore fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add emergency contact to user
  Future<void> addEmergencyContact(String contactId) async {
    final List<String> updatedContacts = List.from(_currentUser.emergencyContactIds);
    
    if (!updatedContacts.contains(contactId)) {
      updatedContacts.add(contactId);
      
      await updateUser(
        emergencyContactIds: updatedContacts,
      );
    }
  }
  
  // Remove emergency contact from user
  Future<void> removeEmergencyContact(String contactId) async {
    final List<String> updatedContacts = List.from(_currentUser.emergencyContactIds);
    
    if (updatedContacts.contains(contactId)) {
      updatedContacts.remove(contactId);
      
      await updateUser(
        emergencyContactIds: updatedContacts,
      );
    }
  }
  
  // Accept disclaimer
  Future<void> acceptDisclaimer() async {
    await updateUser(
      hasAcceptedDisclaimer: true,
    );
  }
  
  // Complete onboarding
  Future<void> completeOnboarding({
    required String name,
    required Gender gender,
    required double weight,
    required int age,
  }) async {
    await updateUser(
      name: name,
      gender: gender,
      weight: weight,
      age: age,
    );
  }
  
  // Sign out user (for future auth implementation)
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    
    _initializeUser(); // Will create a new user
  }
}