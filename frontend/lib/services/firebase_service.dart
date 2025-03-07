import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:barbuddy/utils/app_config.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
  
  // Firebase instances
  late final FirebaseApp _app;
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseAnalytics _analytics;
  
  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseAnalytics get analytics => _analytics;
  
  // Initialize Firebase
  Future<void> initialize() async {
    try {
      // Initialize Firebase core
      _app = await Firebase.initializeApp();
      
      // Initialize Firebase Auth
      _auth = FirebaseAuth.instance;
      
      // Initialize Firestore with settings
      _firestore = FirebaseFirestore.instance;
      
      // Apply settings based on environment
      if (AppConfig.isDevelopment) {
        // Use local emulators for development if available
        if (const bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false)) {
          await _connectToEmulators();
        }
        
        // Enable more debugging features in development
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
      
      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      
      // Disable analytics in development mode
      if (AppConfig.isDevelopment || !AppConfig.instance.analytics) {
        await _analytics.setAnalyticsCollectionEnabled(false);
      }
      
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
  
  // Connect to local Firebase emulators for development
  Future<void> _connectToEmulators() async {
    const authHost = '127.0.0.1';
    const authPort = 9099;
    const firestoreHost = '127.0.0.1';
    const firestorePort = 8080;
    
    // Connect to Auth emulator
    await _auth.useAuthEmulator(authHost, authPort);
    debugPrint('Connected to Auth emulator at $authHost:$authPort');
    
    // Connect to Firestore emulator
    _firestore.useFirestoreEmulator(firestoreHost, firestorePort);
    debugPrint('Connected to Firestore emulator at $firestoreHost:$firestorePort');
  }
  
  // Sign in anonymously (for users who don't want to create an account)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }
  
  // Get current user ID or create anonymous user if none exists
  Future<String> getCurrentUserId() async {
    User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      // No user found, create anonymous account
      final userCredential = await signInAnonymously();
      currentUser = userCredential.user;
    }
    
    return currentUser?.uid ?? '';
  }
  
  // Log analytics event
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {
    if (AppConfig.instance.analytics) {
      await _analytics.logEvent(name: name, parameters: parameters);
    }
  }
}