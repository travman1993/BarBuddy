import 'package:barbuddy/utils/constants.dart';

enum BACLevel {
  safe,    // Below caution threshold
  caution, // Between caution and legal limit
  warning, // At or above legal limit but below high threshold
  danger   // High BAC
}

class BACEstimate {
  final double bac;           // Current BAC level
  final DateTime timestamp;   // When this estimation was made
  final DateTime soberTime;   // Estimated time when BAC will be 0
  final DateTime legalTime;   // Estimated time when BAC will be below legal limit
  final List<String> drinkIds; // IDs of drinks included in this calculation
  
  BACEstimate({
    required this.bac,
    required this.timestamp,
    required this.soberTime,
    required this.legalTime,
    required this.drinkIds,
  });
  
  // Get BAC level category
  BACLevel get level {
    if (bac >= kHighBACThreshold) {
      return BACLevel.danger;
    } else if (bac >= kLegalDrivingLimit) {
      return BACLevel.warning;
    } else if (bac >= kCautionBACThreshold) {
      return BACLevel.caution;
    } else {
      return BACLevel.safe;
    }
  }
  
  // Minutes until BAC is below legal limit
  int get minutesUntilLegal {
    final difference = legalTime.difference(DateTime.now());
    return difference.inMinutes < 0 ? 0 : difference.inMinutes;
  }
  
  // Minutes until completely sober
  int get minutesUntilSober {
    final difference = soberTime.difference(DateTime.now());
    return difference.inMinutes < 0 ? 0 : difference.inMinutes;
  }
  
  // Format time remaining until legal BAC
  String get timeUntilLegalFormatted {
    if (bac < kLegalDrivingLimit) {
      return 'You are under the legal limit';
    }
    
    final hours = minutesUntilLegal ~/ 60;
    final minutes = minutesUntilLegal % 60;
    
    if (hours > 0) {
      return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    } else {
      return '${minutes.toString().padLeft(2, '0')} min';
    }
  }
  
  // Format time remaining until completely sober
  String get timeUntilSoberFormatted {
    if (bac <= 0) {
      return 'You are sober';
    }
    
    final hours = minutesUntilSober ~/ 60;
    final minutes = minutesUntilSober % 60;
    
    if (hours > 0) {
      return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    } else {
      return '${minutes.toString().padLeft(2, '0')} min';
    }
  }
  
  // Get advice based on current BAC level
  String get advice {
    switch (level) {
      case BACLevel.safe:
        return 'You appear to be at a low BAC level. Remember that impairment can begin with the first drink.';
      case BACLevel.caution:
        return 'You are approaching the legal limit. It\'s recommended to stop drinking and consider arranging a ride if needed.';
      case BACLevel.warning:
        return 'You are at or above the legal limit for driving. DO NOT drive. Consider calling a ride-sharing service or a friend.';
      case BACLevel.danger:
        return 'Your BAC is at a high level. DO NOT drive under any circumstances. Stay hydrated and consider getting medical help if you feel unwell.';
    }
  }
  
  // Create a copy with new values
  BACEstimate copyWith({
    double? bac,
    DateTime? timestamp,
    DateTime? soberTime,
    DateTime? legalTime,
    List<String>? drinkIds,
  }) {
    return BACEstimate(
      bac: bac ?? this.bac,
      timestamp: timestamp ?? this.timestamp,
      soberTime: soberTime ?? this.soberTime,
      legalTime: legalTime ?? this.legalTime,
      drinkIds: drinkIds ?? this.drinkIds,
    );
  }
  
  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'bac': bac,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'soberTime': soberTime.millisecondsSinceEpoch,
      'legalTime': legalTime.millisecondsSinceEpoch,
      'drinkIds': drinkIds,
    };
  }
  
  // Create from map
  factory BACEstimate.fromMap(Map<String, dynamic> map) {
    return BACEstimate(
      bac: map['bac'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      soberTime: DateTime.fromMillisecondsSinceEpoch(map['soberTime']),
      legalTime: DateTime.fromMillisecondsSinceEpoch(map['legalTime']),
      drinkIds: List<String>.from(map['drinkIds']),
    );
  }
  
  // Create an empty BAC estimate (sober)
  factory BACEstimate.empty() {
    final now = DateTime.now();
    return BACEstimate(
      bac: 0.0,
      timestamp: now,
      soberTime: now,
      legalTime: now,
      drinkIds: [],
    );
  }
}