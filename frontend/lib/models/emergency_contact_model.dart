import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final bool isPrimary;
  final bool enableAutoCheckIn;
  final bool enableEmergencyAlerts;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.isPrimary = false,
    this.enableAutoCheckIn = true,
    this.enableEmergencyAlerts = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'isPrimary': isPrimary,
      'enableAutoCheckIn': enableAutoCheckIn,
      'enableEmergencyAlerts': enableEmergencyAlerts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Document
  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      isPrimary: map['isPrimary'] ?? false,
      enableAutoCheckIn: map['enableAutoCheckIn'] ?? true,
      enableEmergencyAlerts: map['enableEmergencyAlerts'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with changes
  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    bool? isPrimary,
    bool? enableAutoCheckIn,
    bool? enableEmergencyAlerts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      enableAutoCheckIn: enableAutoCheckIn ?? this.enableAutoCheckIn,
      enableEmergencyAlerts: enableEmergencyAlerts ?? this.enableEmergencyAlerts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted phone number
  String get formattedPhoneNumber {
    // Simple US format: (xxx) xxx-xxxx
    String cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned[0] == '1') {
      return '(${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    return phoneNumber; // Return as is if not recognizable format
  }
}