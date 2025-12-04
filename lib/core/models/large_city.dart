import 'package:equatable/equatable.dart';

/// Large City Model
/// Represents a large diverse city where neighborhoods are separate localities
/// 
/// **Philosophy:** Large cities (Brooklyn, LA, Chicago, Tokyo, etc.) have neighborhoods
/// that are vastly different in thought, atmosphere, idea, and identity.
/// These neighborhoods should be separate localities to preserve neighborhood identity.
/// 
/// **Detection Criteria:**
/// - Geographic size (e.g., Houston is huge with many towns inside)
/// - Population size
/// - Well-documented neighborhoods backed by geography and population data
class LargeCity extends Equatable {
  final String id;
  final String name;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final int? population;
  final double? geographicSizeKm2;
  final List<String> neighborhoods; // List of neighborhood locality IDs
  final bool isDetected; // True if detected by system, false if manually added
  final DateTime createdAt;
  final DateTime updatedAt;

  const LargeCity({
    required this.id,
    required this.name,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.population,
    this.geographicSizeKm2,
    this.neighborhoods = const [],
    this.isDetected = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full display name (e.g., "New York City, New York")
  String get displayName {
    if (state != null) {
      return '$name, $state';
    }
    return name;
  }

  /// Check if city has neighborhoods configured
  bool get hasNeighborhoods => neighborhoods.isNotEmpty;

  /// Get neighborhood count
  int get neighborhoodCount => neighborhoods.length;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'population': population,
      'geographicSizeKm2': geographicSizeKm2,
      'neighborhoods': neighborhoods,
      'isDetected': isDetected,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LargeCity.fromJson(Map<String, dynamic> json) {
    return LargeCity(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      population: json['population'] as int?,
      geographicSizeKm2: (json['geographicSizeKm2'] as num?)?.toDouble(),
      neighborhoods: List<String>.from(json['neighborhoods'] as List? ?? []),
      isDetected: json['isDetected'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  LargeCity copyWith({
    String? id,
    String? name,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    int? population,
    double? geographicSizeKm2,
    List<String>? neighborhoods,
    bool? isDetected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LargeCity(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      population: population ?? this.population,
      geographicSizeKm2: geographicSizeKm2 ?? this.geographicSizeKm2,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      isDetected: isDetected ?? this.isDetected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        state,
        country,
        latitude,
        longitude,
        population,
        geographicSizeKm2,
        neighborhoods,
        isDetected,
        createdAt,
        updatedAt,
      ];
}

