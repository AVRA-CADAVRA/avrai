import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:spots/core/models/anonymous_user.dart';

/// Location Obfuscation Service
/// 
/// Obfuscates location data for AI2AI network sharing.
/// 
/// **IMPORTANT:** Obfuscation is only applied for community/business admin.
/// SPOTS godmode allows exact locations to be seen.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to secure AI2AI connections without privacy risk
/// - Protects user location while enabling network participation
/// - Respects admin permissions for exact location access
/// 
/// **Features:**
/// - City-level obfuscation (round coordinates to city center)
/// - Differential privacy (add controlled random noise)
/// - Expiration checks (expire old location data)
/// - Home location protection (never share home location in AI2AI)
/// 
/// **Usage:**
/// ```dart
/// final service = LocationObfuscationService();
/// final obfuscated = await service.obfuscateLocation(
///   locationString,
///   userId,
///   isAdmin: false, // Only obfuscate for non-admin
/// );
/// ```
class LocationObfuscationService {
  static const String _logName = 'LocationObfuscationService';
  
  // Obfuscation settings
  static const double _cityLevelPrecision = 0.01; // ~1km precision
  static const double _differentialPrivacyNoise = 0.005; // ~500m noise
  static const Duration _locationExpiration = Duration(hours: 24);
  
  // Store home locations to prevent sharing
  final Map<String, String> _homeLocations = {};
  
  /// Obfuscate location for AI2AI network sharing
  /// 
  /// **Parameters:**
  /// - `locationString`: Location string (e.g., "Austin, TX" or coordinates)
  /// - `userId`: User ID (to check against home location)
  /// - `isAdmin`: If true, returns exact location (godmode/admin access)
  /// - `exactLatitude`: Optional exact latitude (if available)
  /// - `exactLongitude`: Optional exact longitude (if available)
  /// 
  /// **Returns:**
  /// ObfuscatedLocation with city-level precision (or exact if admin)
  /// 
  /// **Throws:**
  /// - Exception if location is home location (never share home)
  /// - Exception if location cannot be parsed
  Future<ObfuscatedLocation> obfuscateLocation(
    String locationString,
    String userId, {
    bool isAdmin = false,
    double? exactLatitude,
    double? exactLongitude,
  }) async {
    try {
      // Check if this is a home location (never share in AI2AI)
      if (_isHomeLocation(locationString, userId)) {
        throw Exception('Cannot share home location in AI2AI network');
      }
      
      // If admin/godmode, return exact location
      if (isAdmin) {
        developer.log('Admin access: returning exact location', name: _logName);
        return _createExactLocation(locationString, exactLatitude, exactLongitude);
      }
      
      // For non-admin, apply obfuscation
      developer.log('Obfuscating location for AI2AI network', name: _logName);
      
      // Parse location string to extract city/state
      final locationParts = _parseLocationString(locationString);
      
      // If we have exact coordinates, obfuscate them
      double? obfuscatedLat;
      double? obfuscatedLng;
      
      if (exactLatitude != null && exactLongitude != null) {
        // Round to city center (city-level precision)
        obfuscatedLat = _roundToCityCenter(exactLatitude);
        obfuscatedLng = _roundToCityCenter(exactLongitude);
        
        // Add differential privacy noise
        obfuscatedLat = _addDifferentialPrivacyNoise(obfuscatedLat);
        obfuscatedLng = _addDifferentialPrivacyNoise(obfuscatedLng);
      }
      
      // Create obfuscated location
      final obfuscatedLocation = ObfuscatedLocation(
        city: locationParts['city'] ?? 'Unknown',
        state: locationParts['state'],
        country: locationParts['country'],
        latitude: obfuscatedLat,
        longitude: obfuscatedLng,
        expiresAt: DateTime.now().add(_locationExpiration),
      );
      
      developer.log('Location obfuscated successfully', name: _logName);
      return obfuscatedLocation;
    } catch (e) {
      developer.log('Error obfuscating location: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Set home location for a user (to prevent sharing)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `locationString`: Home location string
  void setHomeLocation(String userId, String locationString) {
    _homeLocations[userId] = locationString;
    developer.log('Home location set for user: $userId', name: _logName);
  }
  
  /// Check if location is user's home location
  bool _isHomeLocation(String locationString, String userId) {
    final homeLocation = _homeLocations[userId];
    if (homeLocation == null) {
      return false;
    }
    
    // Normalize both locations for comparison
    final normalizedLocation = locationString.toLowerCase().trim();
    final normalizedHome = homeLocation.toLowerCase().trim();
    
    return normalizedLocation == normalizedHome ||
        normalizedLocation.contains(normalizedHome) ||
        normalizedHome.contains(normalizedLocation);
  }
  
  /// Create exact location (for admin/godmode)
  ObfuscatedLocation _createExactLocation(
    String locationString,
    double? latitude,
    double? longitude,
  ) {
    final locationParts = _parseLocationString(locationString);
    
    return ObfuscatedLocation(
      city: locationParts['city'] ?? locationString,
      state: locationParts['state'],
      country: locationParts['country'],
      latitude: latitude, // Exact latitude (no obfuscation)
      longitude: longitude, // Exact longitude (no obfuscation)
      expiresAt: DateTime.now().add(_locationExpiration),
    );
  }
  
  /// Round coordinates to city center (city-level precision)
  double _roundToCityCenter(double coordinate) {
    // Round to nearest city-level precision (0.01 degrees ≈ 1km)
    return (coordinate / _cityLevelPrecision).round() * _cityLevelPrecision;
  }
  
  /// Add differential privacy noise
  double _addDifferentialPrivacyNoise(double coordinate) {
    final random = math.Random.secure();
    final noise = (random.nextDouble() - 0.5) * 2 * _differentialPrivacyNoise;
    return coordinate + noise;
  }
  
  /// Parse location string to extract city, state, country
  Map<String, String?> _parseLocationString(String locationString) {
    final parts = <String, String?>{};
    
    // Try to parse common formats:
    // "City, State"
    // "City, State, Country"
    // "City"
    final commaParts = locationString.split(',');
    
    if (commaParts.length >= 1) {
      parts['city'] = commaParts[0].trim();
    }
    
    if (commaParts.length >= 2) {
      parts['state'] = commaParts[1].trim();
    }
    
    if (commaParts.length >= 3) {
      parts['country'] = commaParts[2].trim();
    }
    
    return parts;
  }
  
  /// Check if location data has expired
  bool isLocationExpired(ObfuscatedLocation location) {
    return location.isExpired;
  }
  
  /// Clear home location for a user
  void clearHomeLocation(String userId) {
    _homeLocations.remove(userId);
    developer.log('Home location cleared for user: $userId', name: _logName);
  }
}

