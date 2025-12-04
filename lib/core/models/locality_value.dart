import 'package:equatable/equatable.dart';

/// Locality Value Model
/// 
/// Represents analyzed values and preferences for a locality.
/// Tracks what activities are most valued by the community in a specific locality.
/// 
/// **Philosophy:** Local experts shouldn't have to expand past their locality
/// to be qualified. Thresholds adapt to what the locality actually values.
/// 
/// **What This Tracks:**
/// - Events hosted (frequency, success rate)
/// - Lists created (popularity, respects)
/// - Reviews written (quality, peer endorsements)
/// - Event attendance (engagement, return rate)
/// - Professional background (credentials, experience)
/// - Positive activity trends (category + locality)
class LocalityValue extends Equatable {
  final String id;
  final String locality;
  final Map<String, double> activityWeights; // Activity type -> weight (0.0 to 1.0)
  final Map<String, Map<String, double>> categoryPreferences; // Category -> Activity weights
  final Map<String, int> activityCounts; // Activity type -> count
  final DateTime lastAnalyzed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalityValue({
    required this.id,
    required this.locality,
    required this.activityWeights,
    required this.categoryPreferences,
    required this.activityCounts,
    required this.lastAnalyzed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get activity weight for a specific activity type
  double getActivityWeight(String activityType) {
    return activityWeights[activityType] ?? 0.0;
  }

  /// Get category preferences for a specific category
  Map<String, double> getCategoryPreferences(String category) {
    return categoryPreferences[category] ?? activityWeights;
  }

  /// Get activity count for a specific activity type
  int getActivityCount(String activityType) {
    return activityCounts[activityType] ?? 0;
  }

  /// Check if locality values a specific activity highly
  bool valuesActivityHighly(String activityType) {
    final weight = getActivityWeight(activityType);
    return weight >= 0.25; // 25% or higher weight
  }

  /// Get total activity count
  int get totalActivityCount {
    return activityCounts.values.fold(0, (a, b) => a + b);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locality': locality,
      'activityWeights': activityWeights,
      'categoryPreferences': categoryPreferences,
      'activityCounts': activityCounts,
      'lastAnalyzed': lastAnalyzed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LocalityValue.fromJson(Map<String, dynamic> json) {
    return LocalityValue(
      id: json['id'] as String,
      locality: json['locality'] as String,
      activityWeights: Map<String, double>.from(
        json['activityWeights'] as Map,
      ),
      categoryPreferences: (json['categoryPreferences'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                key,
                Map<String, double>.from(value as Map),
              )),
      activityCounts: Map<String, int>.from(
        json['activityCounts'] as Map,
      ),
      lastAnalyzed: DateTime.parse(json['lastAnalyzed'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  LocalityValue copyWith({
    String? id,
    String? locality,
    Map<String, double>? activityWeights,
    Map<String, Map<String, double>>? categoryPreferences,
    Map<String, int>? activityCounts,
    DateTime? lastAnalyzed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalityValue(
      id: id ?? this.id,
      locality: locality ?? this.locality,
      activityWeights: activityWeights ?? this.activityWeights,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      activityCounts: activityCounts ?? this.activityCounts,
      lastAnalyzed: lastAnalyzed ?? this.lastAnalyzed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        locality,
        activityWeights,
        categoryPreferences,
        activityCounts,
        lastAnalyzed,
        createdAt,
        updatedAt,
      ];
}

