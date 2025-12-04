import 'package:equatable/equatable.dart';

/// Cross-Locality Connection Model
/// 
/// Represents a connection between two localities based on user movement patterns.
/// Not just distance-based, but based on actual user behavior and transportation methods.
/// 
/// **Philosophy:** Users discover events in connected localities - places they naturally
/// travel to. This opens doors to neighboring communities and expands event discovery.
class CrossLocalityConnection extends Equatable {
  /// Source locality ID
  final String sourceLocalityId;
  
  /// Source locality name
  final String sourceLocalityName;
  
  /// Target locality ID
  final String targetLocalityId;
  
  /// Target locality name
  final String targetLocalityName;
  
  /// Connection strength (0.0 to 1.0)
  /// Higher strength = more users travel between these localities
  final double connectionStrength;
  
  /// Movement pattern type
  final MovementPatternType patternType;
  
  /// Transportation method used
  final TransportationMethod transportationMethod;
  
  /// Number of users who travel between these localities
  final int userCount;
  
  /// Average travel frequency (times per month)
  final double averageFrequency;
  
  /// Whether both localities are in the same metro area
  final bool isInSameMetroArea;
  
  /// Metro area name (if applicable)
  final String? metroAreaName;
  
  /// Timestamp when connection was calculated
  final DateTime calculatedAt;

  const CrossLocalityConnection({
    required this.sourceLocalityId,
    required this.sourceLocalityName,
    required this.targetLocalityId,
    required this.targetLocalityName,
    required this.connectionStrength,
    required this.patternType,
    required this.transportationMethod,
    required this.userCount,
    required this.averageFrequency,
    required this.isInSameMetroArea,
    this.metroAreaName,
    required this.calculatedAt,
  });

  /// Check if connection is strong (>= 0.7)
  bool get isStrongConnection => connectionStrength >= 0.7;

  /// Check if connection is moderate (0.4 to 0.7)
  bool get isModerateConnection => connectionStrength >= 0.4 && connectionStrength < 0.7;

  /// Check if connection is weak (< 0.4)
  bool get isWeakConnection => connectionStrength < 0.4;

  /// Get display name for the connection
  String get displayName => '$sourceLocalityName → $targetLocalityName';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sourceLocalityId': sourceLocalityId,
      'sourceLocalityName': sourceLocalityName,
      'targetLocalityId': targetLocalityId,
      'targetLocalityName': targetLocalityName,
      'connectionStrength': connectionStrength,
      'patternType': patternType.name,
      'transportationMethod': transportationMethod.name,
      'userCount': userCount,
      'averageFrequency': averageFrequency,
      'isInSameMetroArea': isInSameMetroArea,
      'metroAreaName': metroAreaName,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CrossLocalityConnection.fromJson(Map<String, dynamic> json) {
    return CrossLocalityConnection(
      sourceLocalityId: json['sourceLocalityId'] as String,
      sourceLocalityName: json['sourceLocalityName'] as String,
      targetLocalityId: json['targetLocalityId'] as String,
      targetLocalityName: json['targetLocalityName'] as String,
      connectionStrength: (json['connectionStrength'] as num).toDouble(),
      patternType: MovementPatternType.values.firstWhere(
        (e) => e.name == json['patternType'],
        orElse: () => MovementPatternType.fun,
      ),
      transportationMethod: TransportationMethod.values.firstWhere(
        (e) => e.name == json['transportationMethod'],
        orElse: () => TransportationMethod.car,
      ),
      userCount: json['userCount'] as int? ?? 0,
      averageFrequency: (json['averageFrequency'] as num?)?.toDouble() ?? 0.0,
      isInSameMetroArea: json['isInSameMetroArea'] as bool? ?? false,
      metroAreaName: json['metroAreaName'] as String?,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  /// Copy with method
  CrossLocalityConnection copyWith({
    String? sourceLocalityId,
    String? sourceLocalityName,
    String? targetLocalityId,
    String? targetLocalityName,
    double? connectionStrength,
    MovementPatternType? patternType,
    TransportationMethod? transportationMethod,
    int? userCount,
    double? averageFrequency,
    bool? isInSameMetroArea,
    String? metroAreaName,
    DateTime? calculatedAt,
  }) {
    return CrossLocalityConnection(
      sourceLocalityId: sourceLocalityId ?? this.sourceLocalityId,
      sourceLocalityName: sourceLocalityName ?? this.sourceLocalityName,
      targetLocalityId: targetLocalityId ?? this.targetLocalityId,
      targetLocalityName: targetLocalityName ?? this.targetLocalityName,
      connectionStrength: connectionStrength ?? this.connectionStrength,
      patternType: patternType ?? this.patternType,
      transportationMethod: transportationMethod ?? this.transportationMethod,
      userCount: userCount ?? this.userCount,
      averageFrequency: averageFrequency ?? this.averageFrequency,
      isInSameMetroArea: isInSameMetroArea ?? this.isInSameMetroArea,
      metroAreaName: metroAreaName ?? this.metroAreaName,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  List<Object?> get props => [
        sourceLocalityId,
        sourceLocalityName,
        targetLocalityId,
        targetLocalityName,
        connectionStrength,
        patternType,
        transportationMethod,
        userCount,
        averageFrequency,
        isInSameMetroArea,
        metroAreaName,
        calculatedAt,
      ];
}

/// Movement Pattern Type
/// 
/// Represents the type of movement pattern between localities.
enum MovementPatternType {
  /// Regular commute patterns (work, school)
  commute,
  
  /// Occasional travel patterns (visits, errands)
  travel,
  
  /// Fun/exploration patterns (visiting new places)
  fun,
}

/// Transportation Method
/// 
/// Represents the transportation method used to travel between localities.
enum TransportationMethod {
  /// Car/taxi/rideshare
  car,
  
  /// Public transit (bus, train, subway)
  transit,
  
  /// Walking/biking
  walking,
  
  /// Other methods
  other,
}

