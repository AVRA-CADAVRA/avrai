import 'dart:convert';
import 'dart:io';
import 'package:spots/core/models/source_indicator.dart';

class _Sentinel {
  const _Sentinel();
}

class Spot {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final double rating;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  // Google Places integration
  final String? googlePlaceId; // Google Place ID for syncing with Google Maps
  final DateTime? googlePlaceIdSyncedAt; // When Google Place ID was last synced

  const Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.rating,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.phoneNumber,
    this.website,
    this.imageUrl,
    this.tags = const [],
    this.metadata = const {},
    this.googlePlaceId,
    this.googlePlaceIdSyncedAt,
  });

  Spot copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? category,
    double? rating,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? address = const _Sentinel(),
    Object? phoneNumber = const _Sentinel(),
    Object? website = const _Sentinel(),
    Object? imageUrl = const _Sentinel(),
    List<String>? tags,
    Map<String, dynamic>? metadata,
    Object? googlePlaceId = const _Sentinel(),
    Object? googlePlaceIdSyncedAt = const _Sentinel(),
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address is _Sentinel ? this.address : address as String?,
      phoneNumber:
          phoneNumber is _Sentinel ? this.phoneNumber : phoneNumber as String?,
      website: website is _Sentinel ? this.website : website as String?,
      imageUrl: imageUrl is _Sentinel ? this.imageUrl : imageUrl as String?,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      googlePlaceId: googlePlaceId is _Sentinel
          ? this.googlePlaceId
          : googlePlaceId as String?,
      googlePlaceIdSyncedAt: googlePlaceIdSyncedAt is _Sentinel
          ? this.googlePlaceIdSyncedAt
          : googlePlaceIdSyncedAt as DateTime?,
    );
  }

  /// Check if spot has Google Place ID mapping
  bool get hasGooglePlaceId =>
      googlePlaceId != null && googlePlaceId!.isNotEmpty;

  /// Check if Google Place ID sync is stale (older than 30 days)
  bool get isGooglePlaceIdStale {
    if (googlePlaceIdSyncedAt == null) return true;
    return DateTime.now().difference(googlePlaceIdSyncedAt!) >
        const Duration(days: 30);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'rating': rating,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'address': address,
      'phoneNumber': phoneNumber,
      'website': website,
      'imageUrl': imageUrl,
      'tags': tags,
      'metadata': metadata,
      'googlePlaceId': googlePlaceId,
      'googlePlaceIdSyncedAt': googlePlaceIdSyncedAt?.toIso8601String(),
    };
  }

  factory Spot.fromJson(Map<String, dynamic> json) {
    // #region agent log
    // Debug mode: log input types for numeric conversions (no PII values).
    try {
      final payload = <String, dynamic>{
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H3',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'sessionId': 'debug-session',
        'runId': 'pre-fix-spot-json',
        'hypothesisId': 'H3',
        'location': 'lib/core/models/spot.dart:Spot.fromJson',
        'message': 'Spot.fromJson numeric input types',
        'data': {
          'latitude_type': json['latitude']?.runtimeType.toString(),
          'longitude_type': json['longitude']?.runtimeType.toString(),
          'rating_type': json['rating']?.runtimeType.toString(),
        },
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion

    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Spot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      category: json['category'] ?? '',
      rating: _toDouble(json['rating']),
      createdBy: json['createdBy'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      imageUrl: json['imageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      googlePlaceId: json['googlePlaceId'],
      googlePlaceIdSyncedAt: json['googlePlaceIdSyncedAt'] != null
          ? DateTime.parse(json['googlePlaceIdSyncedAt'])
          : null,
    );
  }

  /// Get source indicator for this spot
  /// Provides transparent data source information (OUR_GUTS.md: "Privacy and Control Are Non-Negotiable")
  SourceIndicator getSourceIndicator() {
    return SourceIndicator.fromSpotMetadata(metadata);
  }
}
