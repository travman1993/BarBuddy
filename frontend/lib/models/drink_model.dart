import 'package:cloud_firestore/cloud_firestore.dart';

enum DrinkType { beer, wine, liquor, cocktail, custom }

class Drink {
  final String id;
  final String userId;
  final DrinkType type;
  final String? name; // Optional custom name
  final double alcoholPercentage; // ABV %
  final double amount; // fluid ounces
  final DateTime timestamp;
  final String? location; // Optional location
  final String? notes; // Optional notes

  Drink({
    required this.id,
    required this.userId,
    required this.type,
    this.name,
    required this.alcoholPercentage,
    required this.amount,
    required this.timestamp,
    this.location,
    this.notes,
  });

  // Get number of standard drinks this represents
  // Standard drink = 0.6 oz of pure alcohol
  double get standardDrinks {
    double pureAlcoholOunces = amount * (alcoholPercentage / 100);
    return pureAlcoholOunces / 0.6;
  }

  // Convert to Document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'name': name,
      'alcoholPercentage': alcoholPercentage,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'notes': notes,
    };
  }

  // Create from Document
  factory Drink.fromMap(Map<String, dynamic> map) {
    DrinkType getType(String type) {
      switch (type) {
        case 'beer':
          return DrinkType.beer;
        case 'wine':
          return DrinkType.wine;
        case 'liquor':
          return DrinkType.liquor;
        case 'cocktail':
          return DrinkType.cocktail;
        default:
          return DrinkType.custom;
      }
    }

    return Drink(
      id: map['id'],
      userId: map['userId'],
      type: getType(map['type']),
      name: map['name'],
      alcoholPercentage: map['alcoholPercentage'] as double,
      amount: map['amount'] as double,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'],
      notes: map['notes'],
    );
  }

  // Create a copy with changes
  Drink copyWith({
    String? id,
    String? userId,
    DrinkType? type,
    String? name,
    double? alcoholPercentage,
    double? amount,
    DateTime? timestamp,
    String? location,
    String? notes,
  }) {
    return Drink(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      alcoholPercentage: alcoholPercentage ?? this.alcoholPercentage,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  // Return a human-readable string representation of the drink
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    switch (type) {
      case DrinkType.beer:
        return 'Beer (${alcoholPercentage.toStringAsFixed(1)}%)';
      case DrinkType.wine:
        return 'Wine (${alcoholPercentage.toStringAsFixed(1)}%)';
      case DrinkType.liquor:
        return 'Liquor (${alcoholPercentage.toStringAsFixed(1)}%)';
      case DrinkType.cocktail:
        return 'Cocktail (${alcoholPercentage.toStringAsFixed(1)}%)';
      case DrinkType.custom:
        return 'Custom Drink (${alcoholPercentage.toStringAsFixed(1)}%)';
    }
  }
}