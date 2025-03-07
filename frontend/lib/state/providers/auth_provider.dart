import 'package:flutter/material.dart';
import 'package:barbuddy/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:barbuddy/models/user_model.dart' as app_models;
import 'package:barbuddy/repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  
  AuthStatus _authStatus = AuthStatus.unknown;
  app_models.User? _user;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  AuthStatus get authStatus => _authStatus;
  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;
  bool get needsOnboarding => _authStatus == AuthStatus.onboarding;
  
  // Constructor
  AuthProvider() {
    _initAuth();
  }
  
  // Initialize authentication state
  Future<void> _initAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Listen for auth state changes
      _authService.authStateChanges.listen((status) {
        _authStatus = status;
        _loadUser();
        notifyListeners();
      });
      
      // Get initial auth status
      _authStatus = await _authService.getCurrentAuthStatus();
      await _loadUser();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing auth: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load user data
  Future<void> _loadUser() async {
    if (_authService.currentUser == null) {
      _user = null;
      return;
    }
    
    try {
      _user = await _userRepository.getUserById(_authService.currentUser!.uid);
    } catch (e) {
      debugPrint('Error loading user: $e');
      _user = null;
    }
  }
  
  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithEmail(email, password);
      await _loadUser();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Error signing in with email: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create user with email and password
  Future<bool> createUserWithEmail(String email, String password, {
    String? name,
    app_models.Gender? gender,
    double? weight,
    int? age,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Create Firebase Auth user
      await _authService.createUserWithEmail(email, password);
      
      // Create Firestore user document
      await _authService.createOrUpdateUserInFirestore(
        name: name,
        gender: gender,
        weight: weight,
        age: age,
      );
      
      await _loadUser();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Error creating user with email: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.signInWithGoogle();
      
      if (result == null) {
        // User canceled the Google Sign In flow
        _error = 'Sign in canceled';
        return false;
      }
      
      // Check if this is a new user
      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        // Create user in Firestore
        await _authService.createOrUpdateUserInFirestore();
      }
      
      await _loadUser();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Error signing in with Google: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInAnonymously();
      
      // Create user in Firestore
      await _authService.createOrUpdateUserInFirestore();
      
      await _loadUser();
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Error signing in anonymously: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signOut();
      _user = null;
      _authStatus = AuthStatus.unauthenticated;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = _parseAuthError(e);
      debugPrint('Error sending password reset email: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile in Firebase Auth
  Future<bool> updateUserProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Update in Firestore if name changed
      if (displayName != null && _user != null) {
        await _userRepository.updateUserFields(_user!.id, {'name': displayName});
      }
      
      await _loadUser();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating user profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user in Firestore
  Future<bool> updateUser({
    String? name,
    app_models.Gender? gender,
    double? weight,
    int? age,
    bool? hasAcceptedDisclaimer,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_user == null || _authService.currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Update user in Firestore
      final updatedUser = _user!.copyWith(
        name: name,
        gender: gender,
        weight: weight,
        age: age,
        hasAcceptedDisclaimer: hasAcceptedDisclaimer,
        updatedAt: DateTime.now(),
      );
      
      _user = await _userRepository.updateUser(updatedUser);
      
      // Update name in Firebase Auth if it changed
      if (name != null && name != _authService.currentUser?.displayName) {
        await _authService.updateUserProfile(displayName: name);
      }
      
      // If disclaimer was accepted, status might change
      if (hasAcceptedDisclaimer == true) {
        _authStatus = AuthStatus.authenticated;
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Complete onboarding
  Future<bool> completeOnboarding({
    required String name,
    required app_models.Gender gender,
    required double weight,
    required int age,
    required bool acceptDisclaimer,
  }) async {
    return await updateUser(
      name: name,
      gender: gender,
      weight: weight,
      age: age,
      hasAcceptedDisclaimer: acceptDisclaimer,
    );
  }
  
  // Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    return await _authService.isEmailInUse(email);
  }
  
  // Helper method to parse Firebase Auth errors
  String _parseAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The email address is already in use.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'operation-not-allowed':
          return 'This sign in method is not allowed.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return error.toString();
  }
  
  // Refresh user data
  Future<void> refreshUser() async {
    if (_authService.currentUser == null) return;
    
    try {
      await _loadUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }
}