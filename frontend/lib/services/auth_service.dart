import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:barbuddy/services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:barbuddy/utils/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:barbuddy/models/user_model.dart' as app_models;
import 'package:barbuddy/repositories/user_repository.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  onboarding,
}

// Define the supported sign-in methods
enum SignInMethod {
  email,
  google,
  anonymous,
}

class AuthService {
  final FirebaseService _firebaseService = FirebaseService();
  final UserRepository _userRepository = UserRepository();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Stream that provides authentication state changes
  Stream<AuthStatus> get authStateChanges {
    return _firebaseService.auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return AuthStatus.unauthenticated;
      }
      
      try {
        // Check if user exists in Firestore
        final appUser = await _userRepository.getUserById(user.uid);
        
        if (appUser == null) {
          // User exists in Firebase but not in Firestore
          return AuthStatus.onboarding;
        }
        
        // Check if user has completed onboarding
        if (!appUser.hasAcceptedDisclaimer) {
          return AuthStatus.onboarding;
        }
        
        return AuthStatus.authenticated;
      } catch (e) {
        debugPrint('Error checking user auth status: $e');
        return AuthStatus.unknown;
      }
    });
  }
  
  // Get current authentication status
  Future<AuthStatus> getCurrentAuthStatus() async {
    final user = _firebaseService.auth.currentUser;
    
    if (user == null) {
      return AuthStatus.unauthenticated;
    }
    
    try {
      // Check if user exists in Firestore
      final appUser = await _userRepository.getUserById(user.uid);
      
      if (appUser == null) {
        return AuthStatus.onboarding;
      }
      
      // Check if user has completed onboarding
      if (!appUser.hasAcceptedDisclaimer) {
        return AuthStatus.onboarding;
      }
      
      return AuthStatus.authenticated;
    } catch (e) {
      debugPrint('Error checking current auth status: $e');
      return AuthStatus.unknown;
    }
  }
  
  // Get current Firebase user
  firebase_auth.User? get currentUser => _firebaseService.auth.currentUser;
  
  // Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'login',
        parameters: {'method': 'email'},
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }
  
  // Create user with email and password
  Future<firebase_auth.UserCredential> createUserWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'sign_up',
        parameters: {'method': 'email'},
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('Error creating user with email: $e');
      rethrow;
    }
  }
  
  // Sign in with Google
  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the Google Sign In flow
        return null;
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseService.auth.signInWithCredential(credential);
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'login',
        parameters: {'method': 'google'},
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
  
  // Sign in anonymously
  Future<firebase_auth.UserCredential> signInAnonymously() async {
    try {
      final userCredential = await _firebaseService.auth.signInAnonymously();
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'login',
        parameters: {'method': 'anonymous'},
      );
      
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out of Google if signed in with Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Sign out of Firebase
      await _firebaseService.auth.signOut();
      
      // Clear secure storage
      await _secureStorage.deleteAll();
      
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _firebaseService.auth.currentUser?.updateDisplayName(displayName);
      await _firebaseService.auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Create or update user in Firestore after authentication
  Future<app_models.User> createOrUpdateUserInFirestore({
    String? name,
    app_models.Gender? gender,
    double? weight,
    int? age,
  }) async {
    final firebaseUser = currentUser;
    
    if (firebaseUser == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      // Check if user exists in Firestore
      final existingUser = await _userRepository.getUserById(firebaseUser.uid);
      
      if (existingUser != null) {
        // Update existing user
        final updatedUser = existingUser.copyWith(
          name: name ?? firebaseUser.displayName ?? existingUser.name,
          gender: gender ?? existingUser.gender,
          weight: weight ?? existingUser.weight,
          age: age ?? existingUser.age,
          updatedAt: DateTime.now(),
        );
        
        return await _userRepository.updateUser(updatedUser);
      } else {
        // Create new user
        final now = DateTime.now();
        final newUser = app_models.User(
          id: firebaseUser.uid,
          name: name ?? firebaseUser.displayName,
          gender: gender ?? app_models.Gender.male,
          weight: weight ?? 160,
          age: age ?? 25,
          hasAcceptedDisclaimer: false,
          createdAt: now,
          updatedAt: now,
        );
        
        return await _userRepository.createUser(newUser);
      }
    } catch (e) {
      debugPrint('Error creating/updating user in Firestore: $e');
      rethrow;
    }
  }
  
  // Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    try {
      final methods = await _firebaseService.auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if email is in use: $e');
      return false;
    }
  }
}