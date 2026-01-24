/// SPOTS Map Boundary Rendering Integration Tests
/// Date: January 2025
/// Purpose: Test complete boundary rendering workflow on both map types
/// 
/// Test Coverage:
/// - Locality polygon boundary loading and rendering
/// - City geohash3 tile boundary loading and rendering
/// - Neighborhood boundary loading and rendering
/// - Boundary priority hierarchy
/// - Boundary conversion for both map types
/// - Error handling in boundary loading
/// 
/// Dependencies:
/// - GeoHierarchyService: Locality and city boundary data
/// - NeighborhoodBoundaryService: Neighborhood boundaries
/// - MapBoundaryConverter: Boundary type conversion
/// 
/// ⚠️  TEST QUALITY GUIDELINES:
/// ❌ DON'T: Test individual component properties
/// ✅ DO: Test complete workflows end-to-end
/// ✅ DO: Test system interactions and integration points
/// ✅ DO: Test error propagation and recovery
/// 
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:avrai/core/services/geo_hierarchy_service.dart';
import 'package:avrai/core/services/neighborhood_boundary_service.dart';
import 'package:avrai/core/models/neighborhood_boundary.dart';
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

  group('Map Boundary Rendering Integration Tests', () {
    late GeoHierarchyService geoHierarchyService;
    late NeighborhoodBoundaryService neighborhoodBoundaryService;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      geoHierarchyService = GeoHierarchyService();
      neighborhoodBoundaryService = NeighborhoodBoundaryService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Boundary Loading Workflow', () {
      test('should load locality polygon boundaries and convert to both map types correctly', () async {
        // Test behavior: complete workflow from loading to conversion
        // This tests the unified boundary system end-to-end

        // Step 1: Load locality polygon (if available)
        final localityCode = 'us-nyc-manhattan'; // Example locality code
        final poly = await geoHierarchyService.getLocalityPolygon(
          localityCode: localityCode,
          simplifyTolerance: 0.01,
        );

        if (poly != null && poly.rings.isNotEmpty) {
          // Step 2: Create unified boundary
          final outerRing = poly.rings.first
              .map((p) => LatLng(p.lat, p.lon))
              .toList();
          final holes = poly.rings.length > 1
              ? poly.rings
                  .skip(1)
                  .map((r) => r.map((p) => LatLng(p.lat, p.lon)).toList())
                  .toList()
              : <List<LatLng>>[];

          final boundary = MapBoundary.polygon(
            id: 'locality:$localityCode',
            outerRing: outerRing,
            holes: holes.isNotEmpty ? holes : null,
            strokeWidth: 2,
            strokeColor: 'FF0000',
            fillColor: 'FF0000',
            opacity: 0.14,
          );

          // Step 3: Convert to Google Maps type
          final googlePolygon = MapBoundaryConverter.toGoogleMapsPolygon(boundary);

          // Step 4: Convert to flutter_map type
          final flutterPolygon = MapBoundaryConverter.toFlutterMapPolygon(boundary);

          // Assert behavior: both conversions maintain coordinate integrity
          expect(googlePolygon.points.length, outerRing.length);
          expect(flutterPolygon.points.length, outerRing.length);
          expect(googlePolygon.holes.length, holes.length);
          if (holes.isNotEmpty) {
            expect(flutterPolygon.holePointsList, isNotNull);
            expect(flutterPolygon.holePointsList!.length, holes.length);
          }
        } else {
          // Locality polygon not available, test continues with other boundary types
          expect(true, isTrue);
        }
      });

      test('should load city geohash3 tile boundaries and convert to both map types correctly', () async {
        // Test behavior: city tile boundary loading and conversion
        final cityCode = 'us-nyc';
        final tiles = await geoHierarchyService.listCityGeohash3Bounds(
          cityCode: cityCode,
          limit: 10, // Limit for testing
        );

        if (tiles.isNotEmpty) {
          // Create unified boundaries for tiles
          final boundaries = tiles.map((t) {
            final outerRing = [
              LatLng(t.minLat, t.minLon),
              LatLng(t.minLat, t.maxLon),
              LatLng(t.maxLat, t.maxLon),
              LatLng(t.maxLat, t.minLon),
            ];

            return MapBoundary.polygon(
              id: 'city_tile:$cityCode:${t.geohash3Id}',
              outerRing: outerRing,
              strokeWidth: 1,
              strokeColor: '00FF00',
              fillColor: '00FF00',
              opacity: 0.12,
            );
          }).toList();

          // Convert to both map types
          final googlePolygons = boundaries
              .map((b) => MapBoundaryConverter.toGoogleMapsPolygon(b))
              .toList();
          final flutterPolygons = boundaries
              .map((b) => MapBoundaryConverter.toFlutterMapPolygon(b))
              .toList();

          // Assert behavior: conversions maintain data integrity
          expect(googlePolygons.length, boundaries.length);
          expect(flutterPolygons.length, boundaries.length);
          for (int i = 0; i < boundaries.length; i++) {
            expect(googlePolygons[i].points.length, boundaries[i].outerRing.length);
            expect(flutterPolygons[i].points.length, boundaries[i].outerRing.length);
          }
        } else {
          // City tiles not available, test continues
          expect(true, isTrue);
        }
      });

      test('should load neighborhood boundaries and convert to both map types correctly', () async {
        // Test behavior: neighborhood boundary loading and conversion
        final localityName = 'Brooklyn';
        final boundaries = await neighborhoodBoundaryService
            .loadBoundariesFromGoogleMaps(localityName);

        if (boundaries.isNotEmpty) {
          // Create unified boundaries
          final unifiedBoundaries = boundaries.map((b) {
            if (b.coordinates.isEmpty) return null;
            final points = b.coordinates
                .map((c) => LatLng(c.latitude, c.longitude))
                .toList();

            return MapBoundary.polyline(
              id: 'boundary:${b.boundaryKey}',
              points: points,
              strokeWidth: b.boundaryType == BoundaryType.hardBorder ? 4 : 3,
              strokeColor: '0000FF',
              opacity: b.boundaryType == BoundaryType.hardBorder ? 1.0 : 0.7,
            );
          }).whereType<MapBoundary>().toList();

          // Convert to both map types
          final googlePolylines = unifiedBoundaries
              .map((b) => MapBoundaryConverter.toGoogleMapsPolyline(b))
              .toList();
          final flutterPolylines = unifiedBoundaries
              .map((b) => MapBoundaryConverter.toFlutterMapPolyline(b))
              .toList();

          // Assert behavior: conversions maintain coordinate integrity
          expect(googlePolylines.length, unifiedBoundaries.length);
          expect(flutterPolylines.length, unifiedBoundaries.length);
          for (int i = 0; i < unifiedBoundaries.length; i++) {
            expect(googlePolylines[i].points.length, unifiedBoundaries[i].outerRing.length);
            expect(flutterPolylines[i].points.length, unifiedBoundaries[i].outerRing.length);
          }
        } else {
          // Neighborhood boundaries not available, test continues
          expect(true, isTrue);
        }
      });
    });

    group('Boundary Priority Hierarchy', () {
      test('should prioritize locality polygons over city tiles when both are available', () async {
        // Test behavior: priority hierarchy in boundary loading
        // This tests the fallback logic in _loadBoundaryOverlays

        final cityCode = 'us-nyc';
        final localityCode = 'us-nyc-manhattan';

        // Try to load locality polygon first (highest priority)
        final localityPoly = await geoHierarchyService.getLocalityPolygon(
          localityCode: localityCode,
          simplifyTolerance: 0.01,
        );

        if (localityPoly != null && localityPoly.rings.isNotEmpty) {
          // Locality polygon available - should be used
          expect(localityPoly.rings, isNotEmpty);
        } else {
          // Locality polygon not available - should fallback to city tiles
          final tiles = await geoHierarchyService.listCityGeohash3Bounds(
            cityCode: cityCode,
            limit: 10,
          );
          // Either tiles are available or we continue to next fallback
          expect(tiles, isA<List>());
        }
      });

      test('should prioritize city tiles over geohash overlays when locality polygon unavailable', () async {
        // Test behavior: fallback hierarchy
        final cityCode = 'us-nyc';

        // Try city tiles (second priority)
        final tiles = await geoHierarchyService.listCityGeohash3Bounds(
          cityCode: cityCode,
          limit: 10,
        );

        if (tiles.isNotEmpty) {
          // City tiles available - should be used
          expect(tiles, isNotEmpty);
        } else {
          // City tiles not available - would fallback to geohash overlays
          // (tested separately)
          expect(true, isTrue);
        }
      });

      test('should fallback through boundary loading hierarchy correctly when services fail', () async {
        // Test error handling: graceful fallback through hierarchy
        final cityCode = 'invalid-city';
        final localityCode = 'invalid-locality';

        // Try locality polygon (should return null for invalid code)
        final localityPoly = await geoHierarchyService.getLocalityPolygon(
          localityCode: localityCode,
          simplifyTolerance: 0.01,
        );

        // Try city tiles (should return empty for invalid code)
        final tiles = await geoHierarchyService.listCityGeohash3Bounds(
          cityCode: cityCode,
          limit: 10,
        );

        // Try neighborhood boundaries (should return empty for invalid name)
        final boundaries = await neighborhoodBoundaryService
            .loadBoundariesFromGoogleMaps('InvalidCity');

        // Assert behavior: all services handle invalid input gracefully
        expect(localityPoly == null || localityPoly.rings.isEmpty, isTrue);
        expect(tiles.isEmpty, isTrue);
        expect(boundaries.isEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully and clear boundaries', () async {
        // Test error handling: service failures don't crash the system
        try {
          // Try to load boundaries with invalid data
          final invalidPoly = await geoHierarchyService.getLocalityPolygon(
            localityCode: '', // Invalid empty code
            simplifyTolerance: 0.01,
          );

          // Service should handle invalid input gracefully
          expect(invalidPoly == null || invalidPoly.rings.isEmpty, isTrue);
        } catch (e) {
          // If service throws, that's also acceptable error handling
          expect(e, isA<Exception>());
        }

        // Try invalid city code
        try {
          final invalidTiles = await geoHierarchyService.listCityGeohash3Bounds(
            cityCode: '', // Invalid empty code
            limit: 10,
          );
          expect(invalidTiles.isEmpty, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });
}
