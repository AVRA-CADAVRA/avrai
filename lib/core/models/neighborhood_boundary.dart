import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

/// Neighborhood Boundary Model
/// 
/// Represents a boundary between two localities (neighborhoods).
/// Boundaries can be hard (well-defined) or soft (blended areas).
/// 
/// **Philosophy:**
/// - Neighborhood boundaries reflect actual community connections (not just geographic lines)
/// - Borders evolve based on user behavior (dynamic refinement)
/// - Soft border spots shared with both localities (community connections)
/// - System learns and refines boundaries based on actual user behavior
/// 
/// **Boundary Types:**
/// - HardBorder: Well-defined boundaries (e.g., NoHo/SoHo) - clear geographic lines
/// - SoftBorder: Not well-defined (e.g., Nolita/East Village) - blended areas
/// 
/// **Key Features:**
/// - Tracks boundary coordinates (list of coordinate points)
/// - Tracks soft border spots (spots in soft border areas)
/// - Tracks user visit counts by locality (which locality visits spots more)
/// - Tracks refinement history (how boundaries have evolved)
/// - Dynamic refinement based on actual user behavior
class NeighborhoodBoundary extends Equatable {
  final String id;
  final String locality1;
  final String locality2;
  final BoundaryType boundaryType;
  final List<CoordinatePoint> coordinates;
  final String source; // e.g., "Google Maps"
  final List<String> softBorderSpots; // List of spot IDs in soft border area
  final Map<String, Map<String, int>> userVisitCounts; // Map<spotId, Map<locality, visitCount>>
  final List<RefinementEvent> refinementHistory;
  final DateTime? lastRefinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NeighborhoodBoundary({
    required this.id,
    required this.locality1,
    required this.locality2,
    required this.boundaryType,
    this.coordinates = const [],
    this.source = 'Google Maps',
    this.softBorderSpots = const [],
    this.userVisitCounts = const {},
    this.refinementHistory = const [],
    this.lastRefinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get boundary key (normalized locality pair)
  /// Returns a consistent key regardless of locality order
  String get boundaryKey {
    final sorted = [locality1, locality2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Check if this is a hard border
  bool get isHardBorder => boundaryType == BoundaryType.hardBorder;

  /// Check if this is a soft border
  bool get isSoftBorder => boundaryType == BoundaryType.softBorder;

  /// Get total visit count for a spot
  int getSpotVisitCount(String spotId) {
    final counts = userVisitCounts[spotId];
    if (counts == null) return 0;
    return counts.values.fold(0, (sum, count) => sum + count);
  }

  /// Get visit count for a spot by locality
  int getSpotVisitCountByLocality(String spotId, String locality) {
    final counts = userVisitCounts[spotId];
    if (counts == null) return 0;
    return counts[locality] ?? 0;
  }

  /// Get dominant locality for a spot (which locality visits it more)
  String? getDominantLocality(String spotId) {
    final counts = userVisitCounts[spotId];
    if (counts == null || counts.isEmpty) return null;

    String? dominantLocality;
    int maxCount = 0;

    counts.forEach((locality, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantLocality = locality;
      }
    });

    return dominantLocality;
  }

  /// Check if spot is in soft border area
  bool isSpotInSoftBorder(String spotId) {
    return softBorderSpots.contains(spotId);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locality1': locality1,
      'locality2': locality2,
      'boundaryType': boundaryType.name,
      'coordinates': coordinates.map((c) => c.toJson()).toList(),
      'source': source,
      'softBorderSpots': softBorderSpots,
      'userVisitCounts': userVisitCounts.map(
        (spotId, counts) => MapEntry(
          spotId,
          counts.map((locality, count) => MapEntry(locality, count)),
        ),
      ),
      'refinementHistory': refinementHistory.map((e) => e.toJson()).toList(),
      'lastRefinedAt': lastRefinedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory NeighborhoodBoundary.fromJson(Map<String, dynamic> json) {
    // #region agent log
    // Debug mode: record coordinate element types so we can prove which path is taken.
    // Avoid PII: do not log ids/names, only types + sizes.
    try {
      final coords = json['coordinates'];
      final coordTypes = <String>[];
      if (coords is List) {
        for (final c in coords.take(3)) {
          coordTypes.add(c.runtimeType.toString());
        }
      }
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H4',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-neighborhood',
        'hypothesisId': 'H4',
        'location': 'lib/core/models/neighborhood_boundary.dart:NeighborhoodBoundary.fromJson',
        'message': 'NeighborhoodBoundary.fromJson coordinates types',
        'data': {
          'coordinates_runtimeType': coords?.runtimeType.toString(),
          'coordinates_len': coords is List ? coords.length : null,
          'coordinates_sample_types': coordTypes,
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    List<CoordinatePoint> _parseCoordinates(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw.map((c) {
          if (c is CoordinatePoint) return c;
          if (c is Map<String, dynamic>) return CoordinatePoint.fromJson(c);
          if (c is Map) return CoordinatePoint.fromJson(Map<String, dynamic>.from(c));
          throw StateError('Unsupported coordinate entry type: ${c.runtimeType}');
        }).toList();
      }
      throw StateError('Unsupported coordinates type: ${raw.runtimeType}');
    }

    return NeighborhoodBoundary(
      id: json['id'] as String,
      locality1: json['locality1'] as String,
      locality2: json['locality2'] as String,
      boundaryType: BoundaryType.values.firstWhere(
        (e) => e.name == json['boundaryType'],
        orElse: () => BoundaryType.softBorder,
      ),
      coordinates: _parseCoordinates(json['coordinates']),
      source: json['source'] as String? ?? 'Google Maps',
      softBorderSpots: (json['softBorderSpots'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      userVisitCounts: (json['userVisitCounts'] as Map<String, dynamic>?)
              ?.map(
                (spotId, counts) => MapEntry(
                  spotId,
                  (counts as Map<String, dynamic>).map(
                    (locality, count) => MapEntry(locality, count as int),
                  ),
                ),
              ) ??
          {},
      refinementHistory: (json['refinementHistory'] as List<dynamic>?)
              ?.map((e) => RefinementEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastRefinedAt: json['lastRefinedAt'] != null
          ? DateTime.parse(json['lastRefinedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  NeighborhoodBoundary copyWith({
    String? id,
    String? locality1,
    String? locality2,
    BoundaryType? boundaryType,
    List<CoordinatePoint>? coordinates,
    String? source,
    List<String>? softBorderSpots,
    Map<String, Map<String, int>>? userVisitCounts,
    List<RefinementEvent>? refinementHistory,
    DateTime? lastRefinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NeighborhoodBoundary(
      id: id ?? this.id,
      locality1: locality1 ?? this.locality1,
      locality2: locality2 ?? this.locality2,
      boundaryType: boundaryType ?? this.boundaryType,
      coordinates: coordinates ?? this.coordinates,
      source: source ?? this.source,
      softBorderSpots: softBorderSpots ?? this.softBorderSpots,
      userVisitCounts: userVisitCounts ?? this.userVisitCounts,
      refinementHistory: refinementHistory ?? this.refinementHistory,
      lastRefinedAt: lastRefinedAt ?? this.lastRefinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        locality1,
        locality2,
        boundaryType,
        coordinates,
        source,
        softBorderSpots,
        userVisitCounts,
        refinementHistory,
        lastRefinedAt,
        createdAt,
        updatedAt,
      ];
}

/// Boundary Type Enum
enum BoundaryType {
  hardBorder,
  softBorder;

  /// Get display name
  String getDisplayName() {
    switch (this) {
      case BoundaryType.hardBorder:
        return 'Hard Border';
      case BoundaryType.softBorder:
        return 'Soft Border';
    }
  }
}

/// Coordinate Point
/// Represents a single coordinate point in a boundary
class CoordinatePoint extends Equatable {
  final double latitude;
  final double longitude;

  const CoordinatePoint({
    required this.latitude,
    required this.longitude,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create from JSON
  factory CoordinatePoint.fromJson(Map<String, dynamic> json) {
    return CoordinatePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Copy with method
  CoordinatePoint copyWith({
    double? latitude,
    double? longitude,
  }) {
    return CoordinatePoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Refinement Event
/// Represents a single refinement event (when boundary was refined, why, how)
class RefinementEvent extends Equatable {
  /// When refinement occurred
  final DateTime timestamp;

  /// Why refinement occurred (e.g., "User behavior pattern detected")
  final String reason;

  /// How refinement occurred (e.g., "Spot visit count analysis")
  final String method;

  /// Changes made (e.g., "Moved spot X from locality1 to locality2")
  final String? changes;

  /// Spot ID that triggered refinement (if applicable)
  final String? spotId;

  /// Previous boundary type (if changed)
  final BoundaryType? previousBoundaryType;

  /// New boundary type (if changed)
  final BoundaryType? newBoundaryType;

  const RefinementEvent({
    required this.timestamp,
    required this.reason,
    required this.method,
    this.changes,
    this.spotId,
    this.previousBoundaryType,
    this.newBoundaryType,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'method': method,
      'changes': changes,
      'spotId': spotId,
      'previousBoundaryType': previousBoundaryType?.name,
      'newBoundaryType': newBoundaryType?.name,
    };
  }

  /// Create from JSON
  factory RefinementEvent.fromJson(Map<String, dynamic> json) {
    return RefinementEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      reason: json['reason'] as String,
      method: json['method'] as String,
      changes: json['changes'] as String?,
      spotId: json['spotId'] as String?,
      previousBoundaryType: json['previousBoundaryType'] != null
          ? BoundaryType.values.firstWhere(
              (e) => e.name == json['previousBoundaryType'],
              orElse: () => BoundaryType.softBorder,
            )
          : null,
      newBoundaryType: json['newBoundaryType'] != null
          ? BoundaryType.values.firstWhere(
              (e) => e.name == json['newBoundaryType'],
              orElse: () => BoundaryType.softBorder,
            )
          : null,
    );
  }

  /// Copy with method
  RefinementEvent copyWith({
    DateTime? timestamp,
    String? reason,
    String? method,
    String? changes,
    String? spotId,
    BoundaryType? previousBoundaryType,
    BoundaryType? newBoundaryType,
  }) {
    return RefinementEvent(
      timestamp: timestamp ?? this.timestamp,
      reason: reason ?? this.reason,
      method: method ?? this.method,
      changes: changes ?? this.changes,
      spotId: spotId ?? this.spotId,
      previousBoundaryType: previousBoundaryType ?? this.previousBoundaryType,
      newBoundaryType: newBoundaryType ?? this.newBoundaryType,
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
        reason,
        method,
        changes,
        spotId,
        previousBoundaryType,
        newBoundaryType,
      ];
}

