import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbuddy/models/emergency_contact_model.dart';
import 'package:barbuddy/services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class EmergencyContactRepository {
  final FirebaseService _firebaseService = FirebaseService();
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
    try {
      final String id = _uuid.v4();
      final DateTime now = DateTime.now();
      
      // If this contact is being set as primary, update any existing ones
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
      
      await _firebaseService.firestore
          .collection(_collection)
          .doc(id)
          .set(contact.toMap());
      
      return contact;
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      rethrow;
    }
  }
  
  // Update an emergency contact
  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    try {
      // Check if updating to primary status
      if (contact.isPrimary) {
        await _updateExistingPrimaryContacts(contact.userId, excludeId: contact.id);
      }
      
      // Update the contact with current timestamp
      final updatedContact = contact.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await _firebaseService.firestore
          .collection(_collection)
          .doc(contact.id)
          .update(updatedContact.toMap());
      
      return updatedContact;
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      rethrow;
    }
  }
  
  // Delete an emergency contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _firebaseService.firestore
          .collection(_collection)
          .doc(contactId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      rethrow;
    }
  }
  
  // Get an emergency contact by ID
  Future<EmergencyContact?> getContactById(String contactId) async {
    try {
      final docSnapshot = await _firebaseService.firestore
          .collection(_collection)
          .doc(contactId)
          .get();
      
      if (docSnapshot.exists) {
        return EmergencyContact.fromMap(docSnapshot.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting emergency contact: $e');
      rethrow;
    }
  }
  
  // Get all emergency contacts for a user
  Future<List<EmergencyContact>> getUserContacts(String userId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EmergencyContact.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user emergency contacts: $e');
      rethrow;
    }
  }
  
  // Get the primary emergency contact for a user
  Future<EmergencyContact?> getPrimaryContact(String userId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return EmergencyContact.fromMap(querySnapshot.docs.first.data());
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting primary emergency contact: $e');
      rethrow;
    }
  }
  
  // Set a contact as primary (and ensure all others are not)
  Future<void> setPrimaryContact(String contactId, String userId) async {
    try {
      // First update all existing primary contacts
      await _updateExistingPrimaryContacts(userId);
      
      // Then set this contact as primary
      await _firebaseService.firestore
          .collection(_collection)
          .doc(contactId)
          .update({
            'isPrimary': true,
            'updatedAt': Timestamp.now(),
          });
    } catch (e) {
      debugPrint('Error setting primary contact: $e');
      rethrow;
    }
  }
  
  // Helper method to update existing primary contacts
  Future<void> _updateExistingPrimaryContacts(String userId, {String? excludeId}) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isPrimary', isEqualTo: true)
          .get();
      
      final batch = _firebaseService.firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        if (excludeId == null || doc.id != excludeId) {
          batch.update(doc.reference, {
            'isPrimary': false,
            'updatedAt': Timestamp.now(),
          });
        }
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating existing primary contacts: $e');
      rethrow;
    }
  }
  
  // Stream of user emergency contacts for real-time updates
  Stream<List<EmergencyContact>> streamUserContacts(String userId) {
    try {
      return _firebaseService.firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => EmergencyContact.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error streaming user emergency contacts: $e');
      rethrow;
    }
  }
}