import 'package:flutter/material.dart';
import 'package:barbuddy/models/user_model.dart';
import 'package:barbuddy/repositories/user_repository.dart';
import 'package:barbuddy/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final FirebaseService _firebaseService = FirebaseService();
  
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
  
  // Initialize user from Firebase or create a new one
  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get current Firebase user ID
      final userId = await _firebaseService.getCurrentUserId();
      
      // Save user ID to local preferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      
      // Get or create user in Firestore
      _currentUser = await _userRepository.getOrCreateUser(userId);
      
      // Check if this is first time (no disclaimer acceptance)
      _isFirstTime = !_currentUser.hasAcceptedDisclaimer;
    } catch (e) {
      debugPrint('Error initializing user: $e');
      _createLocalUser(); // Fallback to local user if Firebase fails
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create a local user as fallback
  void _createLocalUser() {
    final String id = 'local_user';
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
      // Update local user object
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
      await _userRepository.updateUser(_currentUser);
      
      // If this was the first update with disclaimer acceptance, update firstTime flag
      if (hasAcceptedDisclaimer == true) {
        _isFirstTime = false;
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      // We still keep the updated user in memory even if Firestore update fails
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
    required int? age,
  }) async {
    await updateUser(
      name: name,
      gender: gender,
      weight: weight,
      age: age,
    );
  }
  
  // Sign out and reset user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Sign out from Firebase Auth
      await _firebaseService.auth.signOut();
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Reset to a new user
      await _initializeUser();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  // Refresh user data from Firebase
  Future<void> refreshUser() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final updatedUser = await _userRepository.getUserById(_currentUser.id);
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        _isFirstTime = !updatedUser.hasAcceptedDisclaimer;
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}