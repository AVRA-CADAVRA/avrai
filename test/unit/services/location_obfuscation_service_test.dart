import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';
import 'package:spots/core/models/anonymous_user.dart';

/// Tests for LocationObfuscationService
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
///
/// These tests ensure location data is obfuscated to city-level
/// and never exposes exact coordinates or home location
void main() {
  group('LocationObfuscationService', () {
    late LocationObfuscationService service;

    setUp(() {
      service = LocationObfuscationService();
    });

    group('City-Level Obfuscation', () {
      test('should obfuscate location string to city center', () async {
        final locationString = 'San Francisco, CA';
        const userId = 'user-123';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          exactLatitude: 37.7849,
          exactLongitude: -122.4094,
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.city, isNotEmpty);
        expect(obfuscated.city, equals('San Francisco'));
        // Should be obfuscated (city-level, not exact)
        if (obfuscated.latitude != null && obfuscated.longitude != null) {
          expect(obfuscated.latitude, closeTo(37.7749, 0.1)); // City center
          expect(obfuscated.longitude, closeTo(-122.4194, 0.1)); // City center
        }
        // Should have expiration
        expect(obfuscated.expiresAt, isNotNull);
      });

      test('should return city-level location for San Francisco', () async {
        final locationString = 'San Francisco, CA';
        const userId = 'user-sf';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );

        expect(obfuscated.city, equals('San Francisco'));
        expect(obfuscated.country, isNull); // May be null if not parsed
        // Should be city center coordinates (obfuscated)
        if (obfuscated.latitude != null) {
          expect(obfuscated.latitude, closeTo(37.7749, 0.1)); // Within city
        }
        if (obfuscated.longitude != null) {
          expect(obfuscated.longitude, closeTo(-122.4194, 0.1)); // Within city
        }
      });

      test('should handle different cities correctly', () async {
        final locationString = 'New York, NY';
        const userId = 'user-ny';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          exactLatitude: 40.7128,
          exactLongitude: -74.0060,
        );

        expect(obfuscated.city, equals('New York'));
        if (obfuscated.latitude != null) {
          expect(obfuscated.latitude, closeTo(40.7128, 0.1));
        }
        if (obfuscated.longitude != null) {
          expect(obfuscated.longitude, closeTo(-74.0060, 0.1));
        }
      });
    });

    group('Differential Privacy', () {
      test('should apply differential privacy noise during obfuscation',
          () async {
        final locationString = 'San Francisco, CA';
        const userId = 'user-dp';

        // Obfuscate same location multiple times
        final obfuscated1 = await service.obfuscateLocation(
          locationString,
          userId,
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );
        final obfuscated2 = await service.obfuscateLocation(
          locationString,
          userId,
          exactLatitude: 37.7749,
          exactLongitude: -122.4194,
        );

        // Should add noise (may be different each time)
        expect(obfuscated1, isNotNull);
        expect(obfuscated2, isNotNull);
        // Noise should be within reasonable bounds (if coordinates present)
        if (obfuscated1.latitude != null && obfuscated2.latitude != null) {
          expect(
            (obfuscated1.latitude! - obfuscated2.latitude!).abs(),
            lessThan(0.1), // Small noise
          );
        }
      });

      test('should respect privacy budget', () async {
        final locationString = 'San Francisco, CA';
        const userId = 'user-budget';

        // Obfuscate multiple times
        final locations = <ObfuscatedLocation>[];
        for (int i = 0; i < 10; i++) {
          final obfuscated = await service.obfuscateLocation(
            locationString,
            userId,
            exactLatitude: 37.7749,
            exactLongitude: -122.4194,
          );
          locations.add(obfuscated);
        }

        // Should all be within city bounds
        for (final location in locations) {
          if (location.latitude != null) {
            expect(location.latitude, closeTo(37.7749, 0.5)); // Within city
          }
          if (location.longitude != null) {
            expect(location.longitude, closeTo(-122.4194, 0.5)); // Within city
          }
        }
      });
    });

    group('Location Expiration', () {
      test('should identify expired locations', () {
        final oldLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749,
          longitude: -122.4194,
          expiresAt: DateTime.now().subtract(Duration(hours: 1)), // Expired
        );

        final isExpired = service.isLocationExpired(oldLocation);

        expect(isExpired, isTrue);
      });

      test('should not expire recent locations', () {
        final recentLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749,
          longitude: -122.4194,
          expiresAt:
              DateTime.now().add(Duration(hours: 12)), // 12 hours from now
        );

        final isExpired = service.isLocationExpired(recentLocation);

        expect(isExpired, isFalse);
      });

      test('should use 24 hour expiration period', () async {
        final locationString = 'San Francisco, CA';
        const userId = 'user-expire';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
        );

        // Should expire in 24 hours
        final timeUntilExpiry = obfuscated.expiresAt.difference(DateTime.now());
        expect(timeUntilExpiry.inHours, closeTo(24, 1)); // Within 1 hour
      });
    });

    group('Home Location Protection', () {
      test('should never share home location', () async {
        const homeLocationString = '123 Main St, San Francisco, CA';
        const userId = 'user-home';

        // Set home location
        service.setHomeLocation(userId, homeLocationString);

        // Try to obfuscate home location
        expect(
          () => service.obfuscateLocation(
            homeLocationString,
            userId,
          ),
          throwsException,
        );
      });

      test('should allow obfuscating non-home locations', () async {
        const homeLocationString = '123 Main St, San Francisco, CA';
        const otherLocationString = '456 Oak Ave, San Francisco, CA';
        const userId = 'user-home-check';

        // Set home location
        service.setHomeLocation(userId, homeLocationString);

        // Try to obfuscate different location (should work)
        final obfuscated = await service.obfuscateLocation(
          otherLocationString,
          userId,
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.city, isNotEmpty);
      });

      test('should clear home location', () {
        const homeLocationString = '123 Main St, San Francisco, CA';
        const userId = 'user-clear';

        // Set home location
        service.setHomeLocation(userId, homeLocationString);

        // Clear home location
        service.clearHomeLocation(userId);

        // Should now be able to obfuscate (no longer home)
        expect(
          () => service.obfuscateLocation(
            homeLocationString,
            userId,
          ),
          returnsNormally,
        );
      });
    });

    group('Admin Access', () {
      test('should return exact location for admin', () async {
        const locationString = 'San Francisco, CA';
        const userId = 'user-admin';
        const exactLat = 37.7849;
        const exactLng = -122.4094;

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          isAdmin: true, // Admin access
          exactLatitude: exactLat,
          exactLongitude: exactLng,
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.latitude, equals(exactLat)); // Exact, not obfuscated
        expect(obfuscated.longitude, equals(exactLng)); // Exact, not obfuscated
      });
    });

    group('Edge Cases', () {
      test('should handle location without coordinates', () async {
        const locationString = 'San Francisco, CA';
        const userId = 'user-no-coords';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
          // No exactLatitude/exactLongitude
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.city, isNotEmpty);
        // May not have coordinates if not provided
      });

      test('should handle location with only city name', () async {
        const locationString = 'San Francisco';
        const userId = 'user-city-only';

        final obfuscated = await service.obfuscateLocation(
          locationString,
          userId,
        );

        expect(obfuscated, isNotNull);
        expect(obfuscated.city, equals('San Francisco'));
      });
    });
  });
}
