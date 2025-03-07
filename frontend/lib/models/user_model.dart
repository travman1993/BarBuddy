import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other }

class User {
  final String id;
  final String? name;
  final Gender gender;
  final double weight; // in pounds
  final int age;
  final bool hasAcceptedDisclaimer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> emergencyContactIds;

  User({
    required this.id,
    this.name,
    required this.gender,
    required this.weight,
    required this.age,
    required this.hasAcceptedDisclaimer,
    required this.createdAt,
    required this.updatedAt,
    this.emergencyContactIds = const [],
  });

  // Calculate body water constant based on gender
  double get bodyWaterConstant {
    switch (gender) {
      case Gender.male:
        return 0.68;
      case Gender.female:
        return 0.55;
      case Gender.other:
        return 0.615; // Average of male and female constants
    }
  }

  // Convert to Document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender.toString().split('.').last,
      'weight': weight,
      'age': age,
      'hasAcceptedDisclaimer': hasAcceptedDisclaimer,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'emergencyContactIds': emergencyContactIds,
    };
  }

  // Create from Document
  factory User.fromMap(Map<String, dynamic> map) {
    Gender getGender(String gender) {
      switch (gender) {
        case 'male':
          return Gender.male;
        case 'female':
          return Gender.female;
        default:
          return Gender.other;
      }
    }

    return User(
      id: map['id'],
      name: map['name'],
      gender: getGender(map['gender']),
      weight: map['weight'] as double,
      age: map['age'] as int,
      hasAcceptedDisclaimer: map['hasAcceptedDisclaimer'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      emergencyContactIds: List<String>.from(map['emergencyContactIds'] ?? []),
    );
  }

  // Create copy with changes
  User copyWith({
    String? id,
    String? name,
    Gender? gender,
    double? weight,
    int? age,
    bool? hasAcceptedDisclaimer,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? emergencyContactIds,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      hasAcceptedDisclaimer: hasAcceptedDisclaimer ?? this.hasAcceptedDisclaimer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emergencyContactIds: emergencyContactIds ?? this.emergencyContactIds,
    );
  }
}