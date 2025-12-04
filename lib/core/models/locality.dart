import 'package:equatable/equatable.dart';

/// Locality Model
/// Represents a geographic locality (neighborhood, borough, district, etc.)
/// 
/// **Philosophy:** Local experts are the bread and butter of SPOTS.
/// They don't need city-wide reach to host events - they can host in their locality.
/// 
/// **Large Cities:** In large diverse cities (Brooklyn, LA, etc.), neighborhoods
/// are separate localities to preserve neighborhood identity.
class Locality extends Equatable {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final bool isNeighborhood; // True if this is a neighborhood in a large city
  final String? parentCity; // For neighborhoods, the parent city (e.g., "Brooklyn" for "Greenpoint")
  final DateTime createdAt;
  final DateTime updatedAt;

  const Locality({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.isNeighborhood = false,
    this.parentCity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full display name (e.g., "Greenpoint, Brooklyn" or "Austin, Texas")
  String get displayName {
    if (isNeighborhood && parentCity != null) {
      return '$name, $parentCity';
    }
    if (city != null && state != null) {
      return '$name, $state';
    }
    if (city != null) {
      return '$name, $city';
    }
    return name;
  }

  /// Check if this locality is in a large city
  bool get isInLargeCity => isNeighborhood && parentCity != null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isNeighborhood': isNeighborhood,
      'parentCity': parentCity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Locality.fromJson(Map<String, dynamic> json) {
    return Locality(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isNeighborhood: json['isNeighborhood'] as bool? ?? false,
      parentCity: json['parentCity'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  Locality copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    bool? isNeighborhood,
    String? parentCity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Locality(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isNeighborhood: isNeighborhood ?? this.isNeighborhood,
      parentCity: parentCity ?? this.parentCity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        city,
        state,
        country,
        latitude,
        longitude,
        isNeighborhood,
        parentCity,
        createdAt,
        updatedAt,
      ];
}

