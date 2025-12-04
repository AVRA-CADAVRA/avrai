import 'package:equatable/equatable.dart';
import 'package:spots/core/models/cross_locality_connection.dart';

/// User Movement Pattern Model
/// 
/// Represents a user's movement pattern between localities.
/// Tracks commute, travel, and fun/exploration patterns with frequency and timing.
/// 
/// **Philosophy:** Understanding how users move between localities helps discover
/// events in places they naturally visit. This opens doors to neighboring communities.
class UserMovementPattern extends Equatable {
  /// User ID
  final String userId;
  
  /// Source locality ID
  final String sourceLocalityId;
  
  /// Source locality name
  final String sourceLocalityName;
  
  /// Target locality ID
  final String targetLocalityId;
  
  /// Target locality name
  final String targetLocalityName;
  
  /// Movement pattern type
  final MovementPatternType patternType;
  
  /// Transportation method used
  final TransportationMethod transportationMethod;
  
  /// Frequency of travel (times per month)
  final double frequency;
  
  /// Average time of day for travel (hour of day, 0-23)
  final int? averageTimeOfDay;
  
  /// Days of week when travel occurs (0 = Sunday, 6 = Saturday)
  final List<int> daysOfWeek;
  
  /// Whether this is a regular pattern (commute) or occasional (travel/fun)
  final bool isRegular;
  
  /// First observed date
  final DateTime firstObserved;
  
  /// Last observed date
  final DateTime lastObserved;
  
  /// Total number of observed trips
  final int tripCount;

  const UserMovementPattern({
    required this.userId,
    required this.sourceLocalityId,
    required this.sourceLocalityName,
    required this.targetLocalityId,
    required this.targetLocalityName,
    required this.patternType,
    required this.transportationMethod,
    required this.frequency,
    this.averageTimeOfDay,
    this.daysOfWeek = const [],
    required this.isRegular,
    required this.firstObserved,
    required this.lastObserved,
    required this.tripCount,
  });

  /// Check if pattern is active (observed recently)
  bool isActive({int daysThreshold = 30}) {
    final daysSinceLastObserved = DateTime.now().difference(lastObserved).inDays;
    return daysSinceLastObserved <= daysThreshold;
  }

  /// Get pattern strength (0.0 to 1.0)
  /// Based on frequency, regularity, and recency
  double get patternStrength {
    double strength = 0.0;
    
    // Frequency component (normalized to 0-1, max at 30 trips/month)
    strength += (frequency / 30.0).clamp(0.0, 1.0) * 0.4;
    
    // Regularity component
    if (isRegular) {
      strength += 0.3;
    }
    
    // Recency component (more recent = stronger)
    final daysSinceLastObserved = DateTime.now().difference(lastObserved).inDays;
    if (daysSinceLastObserved <= 7) {
      strength += 0.3;
    } else if (daysSinceLastObserved <= 30) {
      strength += 0.2;
    } else if (daysSinceLastObserved <= 90) {
      strength += 0.1;
    }
    
    return strength.clamp(0.0, 1.0);
  }

  /// Get display name for the pattern
  String get displayName => '$sourceLocalityName → $targetLocalityName';

  /// Get pattern type display name
  String get patternTypeDisplayName {
    switch (patternType) {
      case MovementPatternType.commute:
        return 'Commute';
      case MovementPatternType.travel:
        return 'Travel';
      case MovementPatternType.fun:
        return 'Exploration';
    }
  }

  /// Get transportation method display name
  String get transportationDisplayName {
    switch (transportationMethod) {
      case TransportationMethod.car:
        return 'Car';
      case TransportationMethod.transit:
        return 'Transit';
      case TransportationMethod.walking:
        return 'Walking/Biking';
      case TransportationMethod.other:
        return 'Other';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sourceLocalityId': sourceLocalityId,
      'sourceLocalityName': sourceLocalityName,
      'targetLocalityId': targetLocalityId,
      'targetLocalityName': targetLocalityName,
      'patternType': patternType.name,
      'transportationMethod': transportationMethod.name,
      'frequency': frequency,
      'averageTimeOfDay': averageTimeOfDay,
      'daysOfWeek': daysOfWeek,
      'isRegular': isRegular,
      'firstObserved': firstObserved.toIso8601String(),
      'lastObserved': lastObserved.toIso8601String(),
      'tripCount': tripCount,
      'patternStrength': patternStrength,
    };
  }

  /// Create from JSON
  factory UserMovementPattern.fromJson(Map<String, dynamic> json) {
    return UserMovementPattern(
      userId: json['userId'] as String,
      sourceLocalityId: json['sourceLocalityId'] as String,
      sourceLocalityName: json['sourceLocalityName'] as String,
      targetLocalityId: json['targetLocalityId'] as String,
      targetLocalityName: json['targetLocalityName'] as String,
      patternType: MovementPatternType.values.firstWhere(
        (e) => e.name == json['patternType'],
        orElse: () => MovementPatternType.fun,
      ),
      transportationMethod: TransportationMethod.values.firstWhere(
        (e) => e.name == json['transportationMethod'],
        orElse: () => TransportationMethod.car,
      ),
      frequency: (json['frequency'] as num).toDouble(),
      averageTimeOfDay: json['averageTimeOfDay'] as int?,
      daysOfWeek: List<int>.from(json['daysOfWeek'] as List? ?? []),
      isRegular: json['isRegular'] as bool? ?? false,
      firstObserved: DateTime.parse(json['firstObserved'] as String),
      lastObserved: DateTime.parse(json['lastObserved'] as String),
      tripCount: json['tripCount'] as int? ?? 0,
    );
  }

  /// Copy with method
  UserMovementPattern copyWith({
    String? userId,
    String? sourceLocalityId,
    String? sourceLocalityName,
    String? targetLocalityId,
    String? targetLocalityName,
    MovementPatternType? patternType,
    TransportationMethod? transportationMethod,
    double? frequency,
    int? averageTimeOfDay,
    List<int>? daysOfWeek,
    bool? isRegular,
    DateTime? firstObserved,
    DateTime? lastObserved,
    int? tripCount,
  }) {
    return UserMovementPattern(
      userId: userId ?? this.userId,
      sourceLocalityId: sourceLocalityId ?? this.sourceLocalityId,
      sourceLocalityName: sourceLocalityName ?? this.sourceLocalityName,
      targetLocalityId: targetLocalityId ?? this.targetLocalityId,
      targetLocalityName: targetLocalityName ?? this.targetLocalityName,
      patternType: patternType ?? this.patternType,
      transportationMethod: transportationMethod ?? this.transportationMethod,
      frequency: frequency ?? this.frequency,
      averageTimeOfDay: averageTimeOfDay ?? this.averageTimeOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isRegular: isRegular ?? this.isRegular,
      firstObserved: firstObserved ?? this.firstObserved,
      lastObserved: lastObserved ?? this.lastObserved,
      tripCount: tripCount ?? this.tripCount,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        sourceLocalityId,
        sourceLocalityName,
        targetLocalityId,
        targetLocalityName,
        patternType,
        transportationMethod,
        frequency,
        averageTimeOfDay,
        daysOfWeek,
        isRegular,
        firstObserved,
        lastObserved,
        tripCount,
      ];
}

