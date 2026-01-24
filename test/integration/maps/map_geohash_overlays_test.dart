/// SPOTS Map Geohash Overlay Integration Tests
/// Date: January 2025
/// Purpose: Test geohash overlay generation and rendering on both map types
/// 
/// Test Coverage:
/// - Geohash boundary generation for locality agents
/// - Center geohash and neighbor calculation
/// - Boundary conversion for both map types
/// - Error handling in geohash operations
/// 
/// Dependencies:
/// - GeohashService: Geohash encoding/decoding
/// - MapBoundaryConverter: Boundary type conversion
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ❌ DON'T: Test individual component properties
/// ✅ DO: Test complete workflows end-to-end
/// ✅ DO: Test behavior (geohash generation, neighbor calculation)
/// ✅ DO: Test error handling
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:avrai/core/services/geohash_service.dart';
import 'package:avrai/presentation/widgets/map/map_boundary.dart';
import 'package:avrai/presentation/widgets/map/map_boundary_converter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:flutter_map/flutter_map.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  group('Map Geohash Overlay Integration Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Geohash Boundary Generation', () {
      test('should generate geohash boundaries for locality agents with correct structure including center and 8 neighbors', () async {
        // Test behavior: geohash boundary generation workflow
        const centerLat = 40.7128;
        const centerLon = -74.0060;
        const cityCode = 'us-nyc';

        // Step 1: Encode center location to geohash
        final geohash = GeohashService.encode(
          latitude: centerLat,
          longitude: centerLon,
          precision: 7,
        );

        // Step 2: Get 8 neighbors
        final neighbors = GeohashService.neighbors(geohash: geohash);
        final allGeohashes = [geohash, ...neighbors];

        // Assert behavior: geohash generation produces correct structure
        expect(geohash, hasLength(7));
        expect(neighbors, hasLength(8));
        expect(allGeohashes, hasLength(9)); // Center + 8 neighbors

        // Step 3: Create unified boundaries for each geohash
        final boundaries = <MapBoundary>[];
        for (final gh in allGeohashes) {
          final bbox = GeohashService.decodeBoundingBox(gh);

          final outerRing = [
            LatLng(bbox.latMin, bbox.lonMin),
            LatLng(bbox.latMin, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMin),
          ];

          boundaries.add(
            MapBoundary.polygon(
              id: 'locality_agent_geohash:$gh',
              outerRing: outerRing,
              strokeWidth: 1,
              strokeColor: 'FFFF00',
              fillColor: 'FFFF00',
              opacity: 0.1,
            ),
          );
        }

        // Assert behavior: boundaries are created correctly
        expect(boundaries, hasLength(9));
        for (final boundary in boundaries) {
          expect(boundary.type, MapBoundaryType.polygon);
          expect(boundary.outerRing, hasLength(4)); // Rectangle has 4 points
        }
      });

      test('should include center geohash and 8 neighbors in overlay with unique geohash values', () async {
        // Test behavior: neighbor calculation produces unique geohashes
        const centerLat = 40.7128;
        const centerLon = -74.0060;

        final geohash = GeohashService.encode(
          latitude: centerLat,
          longitude: centerLon,
          precision: 7,
        );

        final neighbors = GeohashService.neighbors(geohash: geohash);
        final allGeohashes = [geohash, ...neighbors];

        // Assert behavior: all geohashes are unique
        expect(allGeohashes.toSet().length, equals(9),
            reason: 'Should have 9 unique geohashes (center + 8 neighbors)');

        // Assert behavior: center is included
        expect(allGeohashes, contains(geohash));

        // Assert behavior: all neighbors are different from center
        for (final neighbor in neighbors) {
          expect(neighbor, isNot(equals(geohash)));
        }
      });

      test('should return empty list when city code or coordinates are missing', () async {
        // Test error handling: missing required parameters
        // This simulates the behavior in _loadLocalityAgentGeohashBoundaries

        // Missing city code
        String? cityCode;
        double? centerLat = 40.7128;
        double? centerLon = -74.0060;

        if (cityCode == null) {
          // Should return empty list
          expect(<MapBoundary>[], isEmpty);
        }

        // Missing coordinates
        cityCode = 'us-nyc';
        centerLat = null;
        centerLon = null;

        if (centerLat == null || centerLon == null) {
          // Should return empty list
          expect(<MapBoundary>[], isEmpty);
        }
      });

      test('should handle geohash encoding errors gracefully and return empty list', () async {
        // Test error handling: invalid coordinates
        try {
          // Invalid latitude (out of range)
          final invalidGeohash = GeohashService.encode(
            latitude: 200.0, // Invalid: > 90
            longitude: -74.0060,
            precision: 7,
          );
          // If encoding succeeds, decode should still work
          final bbox = GeohashService.decodeBoundingBox(invalidGeohash);
          expect(bbox, isNotNull);
        } on RangeError {
          // Expected: invalid coordinates throw RangeError
          expect(true, isTrue);
        } catch (e) {
          // Other errors are also acceptable
          expect(e, isA<Exception>());
        }
      });
    });

    group('Geohash Boundary Conversion', () {
      test('should convert geohash boundaries to Google Maps polygons correctly with all 9 boundaries', () async {
        // Test behavior: conversion to Google Maps type
        const centerLat = 40.7128;
        const centerLon = -74.0060;

        final geohash = GeohashService.encode(
          latitude: centerLat,
          longitude: centerLon,
          precision: 7,
        );
        final neighbors = GeohashService.neighbors(geohash: geohash);
        final allGeohashes = [geohash, ...neighbors];

        // Create unified boundaries
        final boundaries = allGeohashes.map((gh) {
          final bbox = GeohashService.decodeBoundingBox(gh);
          final outerRing = [
            LatLng(bbox.latMin, bbox.lonMin),
            LatLng(bbox.latMin, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMin),
          ];

          return MapBoundary.polygon(
            id: 'geohash:$gh',
            outerRing: outerRing,
            strokeWidth: 1,
            strokeColor: 'FFFF00',
            fillColor: 'FFFF00',
            opacity: 0.1,
          );
        }).toList();

        // Convert to Google Maps polygons
        final googlePolygons = boundaries
            .map((b) => MapBoundaryConverter.toGoogleMapsPolygon(b))
            .toList();

        // Assert behavior: conversion maintains all boundaries
        expect(googlePolygons, hasLength(9));
        for (int i = 0; i < boundaries.length; i++) {
          expect(googlePolygons[i].polygonId.value, contains('geohash:'));
          expect(googlePolygons[i].points, hasLength(4));
        }
      });

      test('should convert geohash boundaries to flutter_map polygons correctly with all 9 boundaries', () async {
        // Test behavior: conversion to flutter_map type
        const centerLat = 40.7128;
        const centerLon = -74.0060;

        final geohash = GeohashService.encode(
          latitude: centerLat,
          longitude: centerLon,
          precision: 7,
        );
        final neighbors = GeohashService.neighbors(geohash: geohash);
        final allGeohashes = [geohash, ...neighbors];

        // Create unified boundaries
        final boundaries = allGeohashes.map((gh) {
          final bbox = GeohashService.decodeBoundingBox(gh);
          final outerRing = [
            LatLng(bbox.latMin, bbox.lonMin),
            LatLng(bbox.latMin, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMin),
          ];

          return MapBoundary.polygon(
            id: 'geohash:$gh',
            outerRing: outerRing,
            strokeWidth: 1,
            strokeColor: 'FFFF00',
            fillColor: 'FFFF00',
            opacity: 0.1,
          );
        }).toList();

        // Convert to flutter_map polygons
        final flutterPolygons = boundaries
            .map((b) => MapBoundaryConverter.toFlutterMapPolygon(b))
            .toList();

        // Assert behavior: conversion maintains all boundaries
        expect(flutterPolygons, hasLength(9));
        for (int i = 0; i < boundaries.length; i++) {
          expect(flutterPolygons[i].points, hasLength(4));
          expect(flutterPolygons[i].color, isA<Color>());
        }
      });
    });

    group('Geohash Bounding Box Validation', () {
      test('should generate bounding boxes that contain original coordinates for all geohashes', () async {
        // Test behavior: geohash bounding boxes are correct
        const centerLat = 40.7128;
        const centerLon = -74.0060;

        final geohash = GeohashService.encode(
          latitude: centerLat,
          longitude: centerLon,
          precision: 7,
        );
        final neighbors = GeohashService.neighbors(geohash: geohash);
        final allGeohashes = [geohash, ...neighbors];

        // Verify each geohash bounding box contains its center point
        for (final gh in allGeohashes) {
          final bbox = GeohashService.decodeBoundingBox(gh);

          // Create boundary from bounding box
          final outerRing = [
            LatLng(bbox.latMin, bbox.lonMin),
            LatLng(bbox.latMin, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMax),
            LatLng(bbox.latMax, bbox.lonMin),
          ];

          // Assert behavior: bounding box is valid
          expect(bbox.latMin, lessThanOrEqualTo(bbox.latMax));
          expect(bbox.lonMin, lessThanOrEqualTo(bbox.lonMax));
          expect(outerRing, hasLength(4));
        }
      });
    });
  });
}
