import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Theme settings
  bool _isDarkMode = false;
  
  // Notification settings
  bool _enableSafetyAlerts = true;
  bool _enableCheckInReminders = true;
  bool _enableBACUpdates = true;
  bool _enableHydrationReminders = true;
  
  // Privacy settings
  bool _saveLocationData = true;
  bool _analyticsEnabled = true;
  
  // Advanced settings
  bool _useMetricUnits = false; // Default to imperial (US) units
  
  // Loading state
  bool _isLoading = true;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get enableSafetyAlerts => _enableSafetyAlerts;
  bool get enableCheckInReminders => _enableCheckInReminders;
  bool get enableBACUpdates => _enableBACUpdates;
  bool get enableHydrationReminders => _enableHydrationReminders;
  bool get saveLocationData => _saveLocationData;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get useMetricUnits => _useMetricUnits;
  bool get isLoading => _isLoading;
  
  // Constructor
  SettingsProvider() {
    _loadSettings();
  }
  
  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Theme settings
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      
      // Notification settings
      _enableSafetyAlerts = prefs.getBool('enableSafetyAlerts') ?? true;
      _enableCheckInReminders = prefs.getBool('enableCheckInReminders') ?? true;
      _enableBACUpdates = prefs.getBool('enableBACUpdates') ?? true;
      _enableHydrationReminders = prefs.getBool('enableHydrationReminders') ?? true;
      
      // Privacy settings
      _saveLocationData = prefs.getBool('saveLocationData') ?? true;
      _analyticsEnabled = prefs.getBool('analyticsEnabled') ?? true;
      
      // Advanced settings
      _useMetricUnits = prefs.getBool('useMetricUnits') ?? false;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Theme settings
      await prefs.setBool('isDarkMode', _isDarkMode);
      
      // Notification settings
      await prefs.setBool('enableSafetyAlerts', _enableSafetyAlerts);
      await prefs.setBool('enableCheckInReminders', _enableCheckInReminders);
      await prefs.setBool('enableBACUpdates', _enableBACUpdates);
      await prefs.setBool('enableHydrationReminders', _enableHydrationReminders);
      
      // Privacy settings
      await prefs.setBool('saveLocationData', _saveLocationData);
      await prefs.setBool('analyticsEnabled', _analyticsEnabled);
      
      // Advanced settings
      await prefs.setBool('useMetricUnits', _useMetricUnits);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
  
  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveSettings();
  }
  
  // Update notification settings
  Future<void> updateNotificationSettings({
    bool? enableSafetyAlerts,
    bool? enableCheckInReminders,
    bool? enableBACUpdates,
    bool? enableHydrationReminders,
  }) async {
    if (enableSafetyAlerts != null) {
      _enableSafetyAlerts = enableSafetyAlerts;
    }
    
    if (enableCheckInReminders != null) {
      _enableCheckInReminders = enableCheckInReminders;
    }
    
    if (enableBACUpdates != null) {
      _enableBACUpdates = enableBACUpdates;
    }
    
    if (enableHydrationReminders != null) {
      _enableHydrationReminders = enableHydrationReminders;
    }
    
    notifyListeners();
    await _saveSettings();
  }
  
  // Update privacy settings
  Future<void> updatePrivacySettings({
    bool? saveLocationData,
    bool? analyticsEnabled,
  }) async {
    if (saveLocationData != null) {
      _saveLocationData = saveLocationData;
    }
    
    if (analyticsEnabled != null) {
      _analyticsEnabled = analyticsEnabled;
    }
    
    notifyListeners();
    await _saveSettings();
  }
  
  // Toggle units (metric/imperial)
  Future<void> toggleUnits() async {
    _useMetricUnits = !_useMetricUnits;
    notifyListeners();
    await _saveSettings();
  }
  
  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _enableSafetyAlerts = true;
    _enableCheckInReminders = true;
    _enableBACUpdates = true;
    _enableHydrationReminders = true;
    _saveLocationData = true;
    _analyticsEnabled = true;
    _useMetricUnits = false;
    
    notifyListeners();
    await _saveSettings();
  }
  
  // Helper to convert weight between units
  double convertWeight(double weight, {bool toMetric = false}) {
    if (toMetric) {
      // Convert lbs to kg
      return weight * 0.453592;
    } else {
      // Convert kg to lbs
      return weight * 2.20462;
    }
  }
  
  // Get weight unit string
  String get weightUnit => _useMetricUnits ? 'kg' : 'lbs';
  
  // Get volume unit string
  String get volumeUnit => _useMetricUnits ? 'ml' : 'oz';
  
  // Convert volume between units
  double convertVolume(double volume, {bool toMetric = false}) {
    if (toMetric) {
      // Convert oz to ml
      return volume * 29.5735;
    } else {
      // Convert ml to oz
      return volume * 0.033814;
    }
  }
}