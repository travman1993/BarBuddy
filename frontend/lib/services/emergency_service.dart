import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barbuddy/models/emergency_contact_model.dart';
import 'package:flutter_sms/flutter_sms.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'emergency_contacts';
  final Uuid _uuid = const Uuid();
  
  // Add a new emergency contact
  Future<EmergencyContact> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    bool isPrimary = false,
    bool enableAutoCheckIn = true,
    bool enableEmergencyAlerts = true,
  }) async {
    final String id = _uuid.v4();
    final DateTime now = DateTime.now();
    
    // If this is marked as primary, update any existing primary contacts
    if (isPrimary) {
      await _updateExistingPrimaryContacts(userId);
    }
    
    final EmergencyContact contact = EmergencyContact(
      id: id,
      userId: userId,
      name: name,
      phoneNumber: phoneNumber,
      isPrimary: isPrimary,
      enableAutoCheckIn: enableAutoCheckIn,
      enableEmergencyAlerts: enableEmergencyAlerts,
      createdAt: now,
      updatedAt: now,
    );
    
    await _firestore
        .collection(_collection)
        .doc(id)
        .set(contact.toMap());
    
    return contact;
  }
  
  // Update an existing emergency contact
  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    final updatedContact = contact.copyWith(
      updatedAt: DateTime.now(),
    );
    
    // If this is being set as primary, update any existing primary contacts
    if (contact.isPrimary) {
      await _updateExistingPrimaryContacts(contact.userId, excludeId: contact.id);
    }
    
    await _firestore
        .collection(_collection)
        .doc(contact.id)
        .update(updatedContact.toMap());
    
    return updatedContact;
  }
  
  // Delete an emergency contact
  Future<void> deleteContact(String contactId) async {
    await _firestore
        .collection(_collection)
        .doc(contactId)
        .delete();
  }
  
  // Get all emergency contacts for a user
  Future<List<EmergencyContact>> getUserContacts(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();
    
    return snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.data()))
        .toList();
  }
  
  // Get the primary emergency contact for a user
  Future<EmergencyContact?> getPrimaryContact(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return null;
    }
    
    return EmergencyContact.fromMap(snapshot.docs.first.data());
  }
  
  // Make a contact the primary one (and ensure no others are primary)
  Future<void> setPrimaryContact(String contactId, String userId) async {
    // First, update all existing primary contacts
    await _updateExistingPrimaryContacts(userId);
    
    // Then set this one as primary
    await _firestore
        .collection(_collection)
        .doc(contactId)
        .update({'isPrimary': true, 'updatedAt': Timestamp.now()});
  }
  
  // Helper method to update existing primary contacts
  Future<void> _updateExistingPrimaryContacts(String userId, {String? excludeId}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isPrimary', isEqualTo: true)
        .get();
    
    for (var doc in snapshot.docs) {
      if (excludeId == null || doc.id != excludeId) {
        await _firestore
            .collection(_collection)
            .doc(doc.id)
            .update({'isPrimary': false, 'updatedAt': Timestamp.now()});
      }
    }
  }
  
  // Call emergency contact
  Future<void> callEmergencyContact(EmergencyContact contact) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: contact.phoneNumber,
    );
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneUri';
    }
  }
  
  // Send a check-in message to emergency contacts
  Future<void> sendCheckInMessage({
    required String userId,
    required String userName,
    bool onlyPrimary = false,
  }) async {
    List<EmergencyContact> contacts;
    
    if (onlyPrimary) {
      final primaryContact = await getPrimaryContact(userId);
      contacts = primaryContact != null ? [primaryContact] : [];
    } else {
      contacts = await getUserContacts(userId);
      contacts = contacts.where((contact) => contact.enableAutoCheckIn).toList();
    }
    
    if (contacts.isEmpty) {
      return;
    }
    
    // Get current location if permission granted
    String locationStr = '';
    try {
      final hasPermission = await _requestLocationPermission();
      
      if (hasPermission) {
        final location = await _getCurrentLocation();
        if (location != null) {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            locationStr = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    
    // Create message
    final String message = locationStr.isNotEmpty
        ? '$userName is checking in. Current location: $locationStr'
        : '$userName is checking in.';
    
    // Send SMS to each contact
    final List<String> recipients = contacts.map((c) => c.phoneNumber).toList();
    
    try {
      await sendSMS(message: message, recipients: recipients);
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      throw 'Failed to send check-in message';
    }
  }
  
  // Send an emergency alert to contacts
  Future<void> sendEmergencyAlert({
    required String userId,
    required String userName,
    String customMessage = '',
  }) async {
    final contacts = await getUserContacts(userId);
    final alertContacts = contacts.where((c) => c.enableEmergencyAlerts).toList();
    
    if (alertContacts.isEmpty) {
      return;
    }
    
    // Get current location if permission granted
    String locationStr = '';
    String locationUrl = '';
    
    try {
      final hasPermission = await _requestLocationPermission();
      
      if (hasPermission) {
        final location = await _getCurrentLocation();
        if (location != null) {
          locationUrl = 'https://maps.google.com/?q=${location.latitude},${location.longitude}';
          
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            locationStr = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
    
    // Create message
    String message = '⚠️ EMERGENCY ALERT: $userName needs help';
    
    if (customMessage.isNotEmpty) {
      message += '\n\n$customMessage';
    }
    
    if (locationStr.isNotEmpty) {
      message += '\n\nCurrent location: $locationStr';
    }
    
    if (locationUrl.isNotEmpty) {
      message += '\n\nMap: $locationUrl';
    }
    
    // Send SMS to each contact
    final List<String> recipients = alertContacts.map((c) => c.phoneNumber).toList();
    
    try {
      await sendSMS(message: message, recipients: recipients);
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      throw 'Failed to send emergency alert';
    }
  }
  
  // Request location permission
  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
  
  // Get current location
  Future<Position?> _getCurrentLocation() async {
    final hasPermission = await _requestLocationPermission();
    
    if (!hasPermission) {
      return null;
    }
    
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
}