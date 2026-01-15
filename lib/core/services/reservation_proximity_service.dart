// Reservation Proximity Service
//
// Phase 10.1: Multi-Layered Check-In System
// Proximity detection via geohashing
//
// Detects when user is in proximity to check-in location using geohash calculations.

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/services/geohash_service.dart';

/// Reservation Proximity Service
///
/// Detects when user is in proximity to check-in location (geohashing).
/// Used to automatically enable NFC check-in option when user is near check-in location.
///
/// **Phase 10.1:** Multi-layered proximity-triggered check-in system
class ReservationProximityService {
  static const String _logName = 'ReservationProximityService';

  /// Default proximity radius in meters (50m = geohash precision 7, ~153m)
  static const double defaultProximityRadiusMeters = 50.0;

  /// Geohash precision for proximity detection (precision 7 ≈ 153m)
  static const int proximityPrecision = 7;

  /// Check if user is in proximity to check-in location
  ///
  /// **Flow:**
  /// 1. Get spot check-in config from metadata
  /// 2. Calculate user geohash at proximity precision
  /// 3. Calculate spot check-in geohash
  /// 4. Check if geohashes match or are adjacent (within radius)
  ///
  /// **Parameters:**
  /// - `spot`: Spot with check-in configuration in metadata
  /// - `userLat`: User's current latitude
  /// - `userLon`: User's current longitude
  /// - `radiusMeters`: Proximity radius in meters (default: 50m)
  ///
  /// **Returns:**
  /// `true` if user is within proximity radius, `false` otherwise
  ///
  /// **Throws:**
  /// - `Exception` if check-in config is missing or invalid
  Future<bool> isInProximity({
    required Spot spot,
    required double userLat,
    required double userLon,
    double radiusMeters = defaultProximityRadiusMeters,
  }) async {
    try {
      // Get check-in config from spot metadata
      final checkInConfig = spot.metadata['check_in_config'];
      if (checkInConfig == null || checkInConfig['enabled'] != true) {
        developer.log(
          'Check-in not enabled for spot: ${spot.id}',
          name: _logName,
        );
        return false;
      }

      final checkInSpot = checkInConfig['check_in_spot'];
      if (checkInSpot == null) {
        developer.log(
          'Check-in spot configuration missing for spot: ${spot.id}',
          name: _logName,
        );
        return false;
      }

      // Get check-in spot coordinates
      final spotLat = (checkInSpot['latitude'] as num?)?.toDouble();
      final spotLon = (checkInSpot['longitude'] as num?)?.toDouble();

      if (spotLat == null || spotLon == null) {
        developer.log(
          'Check-in spot coordinates missing for spot: ${spot.id}',
          name: _logName,
        );
        return false;
      }

      // Calculate geohashes at proximity precision
      final userGeohash = GeohashService.encode(
        latitude: userLat,
        longitude: userLon,
        precision: proximityPrecision,
      );

      final spotGeohash = GeohashService.encode(
        latitude: spotLat,
        longitude: spotLon,
        precision: proximityPrecision,
      );

      // Check geohash proximity (same or adjacent geohashes within radius)
      final inProximity = _checkGeohashProximity(
        userGeohash: userGeohash,
        spotGeohash: spotGeohash,
        userLat: userLat,
        userLon: userLon,
        spotLat: spotLat,
        spotLon: spotLon,
        radiusMeters: radiusMeters,
      );

      developer.log(
        'Proximity check: spot=${spot.id}, userGeohash=$userGeohash, spotGeohash=$spotGeohash, inProximity=$inProximity',
        name: _logName,
      );

      return inProximity;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking proximity: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check geohash proximity (same or adjacent geohashes within radius)
  ///
  /// **Algorithm:**
  /// 1. If geohashes match → in proximity
  /// 2. If geohashes are adjacent (neighbors) → calculate actual distance
  /// 3. If distance ≤ radius → in proximity
  /// 4. Otherwise → not in proximity
  bool _checkGeohashProximity({
    required String userGeohash,
    required String spotGeohash,
    required double userLat,
    required double userLon,
    required double spotLat,
    required double spotLon,
    required double radiusMeters,
  }) {
    // Same geohash → definitely in proximity
    if (userGeohash == spotGeohash) {
      return true;
    }

    // Check if geohashes are adjacent (neighbors)
    final spotNeighbors = GeohashService.neighbors(geohash: spotGeohash);
    if (spotNeighbors.contains(userGeohash)) {
      // Adjacent geohashes → calculate actual distance
      final distance = _calculateDistance(
        userLat,
        userLon,
        spotLat,
        spotLon,
      );

      return distance <= radiusMeters;
    }

    // Not same or adjacent → calculate actual distance
    final distance = _calculateDistance(
      userLat,
      userLon,
      spotLat,
      spotLon,
    );

    return distance <= radiusMeters;
  }

  /// Calculate distance between two points using Haversine formula (in meters)
  ///
  /// **Formula:**
  /// `a = sin²(Δφ/2) + cos(φ1) * cos(φ2) * sin²(Δλ/2)`
  /// `c = 2 * atan2(√a, √(1-a))`
  /// `d = R * c`
  ///
  /// Where:
  /// - φ = latitude (radians)
  /// - λ = longitude (radians)
  /// - R = Earth's radius (6371000 meters)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) => degrees * (math.pi / 180);
}
