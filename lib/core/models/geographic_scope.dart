import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_level.dart';

/// Geographic Scope Model
/// Represents a user's event hosting scope based on their expertise level
/// 
/// **Hierarchy:** Local → City → Regional → National → Global → Universal
/// 
/// **Rules:**
/// - Local experts can only host in their locality
/// - City experts can host in all localities in their city
/// - Regional experts can host in all cities in their region
/// - National experts can host in all states in their nation
/// - Global experts can host globally
/// - Universal experts can host anywhere
class GeographicScope extends Equatable {
  final String userId;
  final ExpertiseLevel level;
  final String? locality; // User's locality (for local experts)
  final String? city; // User's city (for city experts)
  final String? state; // User's state (for regional experts)
  final String? country; // User's country (for national experts)
  final List<String> allowedLocalities; // Localities user can host in
  final List<String> allowedCities; // Cities user can host in
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeographicScope({
    required this.userId,
    required this.level,
    this.locality,
    this.city,
    this.state,
    this.country,
    this.allowedLocalities = const [],
    this.allowedCities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user can host in a specific locality
  bool canHostInLocality(String localityName) {
    switch (level) {
      case ExpertiseLevel.local:
        // Local experts can only host in their locality
        return locality != null && locality!.toLowerCase() == localityName.toLowerCase();
      case ExpertiseLevel.city:
        // City experts can host in all localities in their city
        return allowedLocalities.any(
          (loc) => loc.toLowerCase() == localityName.toLowerCase(),
        );
      case ExpertiseLevel.regional:
      case ExpertiseLevel.national:
      case ExpertiseLevel.global:
      case ExpertiseLevel.universal:
        // Higher level experts can host in any locality
        return true;
    }
  }

  /// Check if user can host in a specific city
  bool canHostInCity(String cityName) {
    switch (level) {
      case ExpertiseLevel.local:
        // Local experts cannot host outside their locality
        return false;
      case ExpertiseLevel.city:
        // City experts can only host in their city
        return city != null && city!.toLowerCase() == cityName.toLowerCase();
      case ExpertiseLevel.regional:
      case ExpertiseLevel.national:
      case ExpertiseLevel.global:
      case ExpertiseLevel.universal:
        // Higher level experts can host in any city
        return true;
    }
  }

  /// Get all localities user can host in
  List<String> getHostableLocalities() {
    return List<String>.from(allowedLocalities);
  }

  /// Get all cities user can host in
  List<String> getHostableCities() {
    return List<String>.from(allowedCities);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level.name,
      'locality': locality,
      'city': city,
      'state': state,
      'country': country,
      'allowedLocalities': allowedLocalities,
      'allowedCities': allowedCities,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GeographicScope.fromJson(Map<String, dynamic> json) {
    return GeographicScope(
      userId: json['userId'] as String,
      level: ExpertiseLevel.fromString(json['level'] as String) ?? ExpertiseLevel.local,
      locality: json['locality'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      allowedLocalities: List<String>.from(json['allowedLocalities'] as List? ?? []),
      allowedCities: List<String>.from(json['allowedCities'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  GeographicScope copyWith({
    String? userId,
    ExpertiseLevel? level,
    String? locality,
    String? city,
    String? state,
    String? country,
    List<String>? allowedLocalities,
    List<String>? allowedCities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeographicScope(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      locality: locality ?? this.locality,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      allowedLocalities: allowedLocalities ?? this.allowedLocalities,
      allowedCities: allowedCities ?? this.allowedCities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        level,
        locality,
        city,
        state,
        country,
        allowedLocalities,
        allowedCities,
        createdAt,
        updatedAt,
      ];
}

