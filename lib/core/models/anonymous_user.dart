import 'package:equatable/equatable.dart';
import 'package:spots/core/models/personality_profile.dart';

/// Anonymous User model for AI2AI network communication
/// 
/// **CRITICAL:** NO personal information fields allowed
/// This model is used when sharing user data in the AI2AI network
/// to ensure zero personal data exposure.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure AI2AI connections without privacy risk
/// - Protects user identity while enabling network participation
/// - Enables trust network without exposing personal information
/// 
/// **MANDATORY:** This model must NEVER contain:
/// - userId, email, name, phone, address, or any personal identifiers
/// - Exact location coordinates (use obfuscated location)
/// - Any data that could identify the user
class AnonymousUser extends Equatable {
  /// Agent ID (required) - anonymous identifier for AI2AI network
  final String agentId;
  
  /// Personality dimensions - safe to share (no personal data)
  final PersonalityProfile? personalityDimensions;
  
  /// Filtered preferences - only non-personal preferences
  final Map<String, dynamic>? preferences;
  
  /// Expertise areas - safe to share
  final String? expertise;
  
  /// Obfuscated location - city-level only, never exact coordinates
  final ObfuscatedLocation? location;
  
  /// Timestamp when this anonymous user data was created
  final DateTime createdAt;
  
  /// Timestamp when this anonymous user data was last updated
  final DateTime updatedAt;
  
  const AnonymousUser({
    required this.agentId,
    this.personalityDimensions,
    this.preferences,
    this.expertise,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Create AnonymousUser from JSON
  factory AnonymousUser.fromJson(Map<String, dynamic> json) {
    return AnonymousUser(
      agentId: json['agentId'] as String,
      personalityDimensions: json['personalityDimensions'] != null
          ? PersonalityProfile.fromJson(json['personalityDimensions'] as Map<String, dynamic>)
          : null,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
      expertise: json['expertise'] as String?,
      location: json['location'] != null
          ? ObfuscatedLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  
  /// Convert AnonymousUser to JSON
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      if (personalityDimensions != null)
        'personalityDimensions': personalityDimensions!.toJson(),
      if (preferences != null) 'preferences': preferences,
      if (expertise != null) 'expertise': expertise,
      if (location != null) 'location': location!.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Validate that this AnonymousUser contains no personal data
  /// Throws exception if personal data is detected
  void validateNoPersonalData() {
    // Check agentId format (should be agent_*)
    if (!agentId.startsWith('agent_')) {
      throw Exception('Invalid agentId format: must start with "agent_"');
    }
    
    // Ensure no personal data fields exist
    // This is a compile-time check, but we validate at runtime too
    final json = toJson();
    final forbiddenKeys = ['userId', 'email', 'name', 'phone', 'address', 'personalInfo'];
    
    for (final key in forbiddenKeys) {
      if (json.containsKey(key)) {
        throw Exception('AnonymousUser contains forbidden field: $key');
      }
    }
  }
  
  /// Create a copy with updated fields
  AnonymousUser copyWith({
    String? agentId,
    PersonalityProfile? personalityDimensions,
    Map<String, dynamic>? preferences,
    String? expertise,
    ObfuscatedLocation? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnonymousUser(
      agentId: agentId ?? this.agentId,
      personalityDimensions: personalityDimensions ?? this.personalityDimensions,
      preferences: preferences ?? this.preferences,
      expertise: expertise ?? this.expertise,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        agentId,
        personalityDimensions,
        preferences,
        expertise,
        location,
        createdAt,
        updatedAt,
      ];
}

/// Obfuscated location data (city-level only)
/// Never contains exact coordinates or home location
class ObfuscatedLocation extends Equatable {
  /// City name (safe to share)
  final String city;
  
  /// State/region (safe to share)
  final String? state;
  
  /// Country (safe to share)
  final String? country;
  
  /// Obfuscated coordinates (city center, not exact location)
  final double? latitude;
  final double? longitude;
  
  /// Expiration timestamp (location data expires after time period)
  final DateTime expiresAt;
  
  const ObfuscatedLocation({
    required this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    required this.expiresAt,
  });
  
  /// Check if location data has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  factory ObfuscatedLocation.fromJson(Map<String, dynamic> json) {
    return ObfuscatedLocation(
      city: json['city'] as String,
      state: json['state'] as String?,
      country: json['country'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [city, state, country, latitude, longitude, expiresAt];
}

