/// SPOTS Neighborhood Boundary Integration Tests
/// Date: November 25, 2025
/// Purpose: Test end-to-end neighborhood boundary flow
/// 
/// Test Coverage:
/// - End-to-end border refinement flow
/// - Soft border spot association
/// - Boundary updates from user behavior
/// - Integration with geographic hierarchy
/// - Integration with large city detection
/// 
/// Dependencies:
/// - NeighborhoodBoundaryService: Boundary management
/// - LargeCityDetectionService: Large city detection
/// - Geographic hierarchy system
/// - Spot/location services

import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/neighborhood_boundary_service.dart';
import 'package:spots/core/services/large_city_detection_service.dart';
import 'package:spots/core/models/neighborhood_boundary.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Neighborhood Boundary Integration Tests', () {
    late NeighborhoodBoundaryService boundaryService;
    late LargeCityDetectionService largeCityService;
    late DateTime testDate;
    late List<Map<String, double>> testCoordinates;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testCoordinates = [
        {'latitude': 40.7295, 'longitude': -73.9545},
        {'latitude': 40.7300, 'longitude': -73.9550},
        {'latitude': 40.7305, 'longitude': -73.9555},
      ];
      boundaryService = NeighborhoodBoundaryService();
      largeCityService = LargeCityDetectionService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End Border Refinement Flow', () {
      test('should refine soft border based on user behavior', () async {
        // Step 1: Create initial soft border
        final initialBoundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2', 'spot-3'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(initialBoundary);

        // Step 2: Track user visits to spots
        // Nolita users visit spot-1 more frequently
        for (int i = 0; i < 20; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'Nolita');
        }
        for (int i = 0; i < 5; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'East Village');
        }

        // East Village users visit spot-2 more frequently
        for (int i = 0; i < 15; i++) {
          await boundaryService.trackSpotVisit('spot-2', 'East Village');
        }
        for (int i = 0; i < 3; i++) {
          await boundaryService.trackSpotVisit('spot-2', 'Nolita');
        }

        // Step 3: Check if border should be refined
        final shouldRefine = await boundaryService.shouldRefineBorder('Nolita', 'East Village');
        expect(shouldRefine, isTrue);

        // Step 4: Calculate refinement
        final refinement = await boundaryService.calculateBorderRefinement('Nolita', 'East Village');
        expect(refinement, isNotNull);
        expect(refinement.changes, isNotEmpty);

        // Step 5: Apply refinement
        await boundaryService.applyBoundaryRefinement('Nolita', 'East Village');

        // Step 6: Verify boundary was updated
        final updated = await boundaryService.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
        expect(updated?.lastRefinedAt, isNotNull);
        expect(updated?.refinementHistory.length, greaterThan(0));
      });

      test('should track complete refinement lifecycle', () async {
        // Create soft border
        final boundary = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Initial state: no refinement
        final initial = await boundaryService.getBoundary('Greenpoint', 'Williamsburg');
        expect(initial?.hasBeenRefined, isFalse);
        expect(initial?.refinementHistory, isEmpty);

        // Track visits
        for (int i = 0; i < 25; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'Greenpoint');
        }
        for (int i = 0; i < 2; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'Williamsburg');
        }

        // Refine border
        await boundaryService.refineSoftBorder('Greenpoint', 'Williamsburg');

        // Verify refinement occurred
        final refined = await boundaryService.getBoundary('Greenpoint', 'Williamsburg');
        expect(refined?.hasBeenRefined, isTrue);
        expect(refined?.refinementHistory, isNotEmpty);
        expect(refined?.lastRefinedAt, isNotNull);
      });
    });

    group('Soft Border Spot Association', () {
      test('should associate spots with localities based on visit patterns', () async {
        // Create soft border with multiple spots
        final boundary = NeighborhoodBoundary(
          id: 'boundary-789',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2', 'spot-3'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Track visits: spot-1 → Nolita, spot-2 → East Village, spot-3 → balanced
        for (int i = 0; i < 20; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'Nolita');
        }
        for (int i = 0; i < 18; i++) {
          await boundaryService.trackSpotVisit('spot-2', 'East Village');
        }
        for (int i = 0; i < 10; i++) {
          await boundaryService.trackSpotVisit('spot-3', 'Nolita');
          await boundaryService.trackSpotVisit('spot-3', 'East Village');
        }

        // Get dominant localities
        final dominant1 = await boundaryService.getDominantLocality('spot-1');
        final dominant2 = await boundaryService.getDominantLocality('spot-2');
        final dominant3 = await boundaryService.getDominantLocality('spot-3');

        expect(dominant1, equals('Nolita'));
        expect(dominant2, equals('East Village'));
        expect(dominant3, equals('Nolita')); // Tie goes to locality1

        // Update associations
        await boundaryService.updateSpotLocalityAssociation('spot-1');
        await boundaryService.updateSpotLocalityAssociation('spot-2');

        // Verify associations
        expect(await boundaryService.getSpotLocalityAssociation('spot-1'), equals('Nolita'));
        expect(await boundaryService.getSpotLocalityAssociation('spot-2'), equals('East Village'));
      });

      test('should handle spots shared between localities', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-shared',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-shared'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Balanced visits (shared spot)
        for (int i = 0; i < 15; i++) {
          await boundaryService.trackSpotVisit('spot-shared', 'Nolita');
          await boundaryService.trackSpotVisit('spot-shared', 'East Village');
        }

        // Spot should remain in soft border (not strongly associated with either)
        final visitCounts = await boundaryService.getSpotVisitCounts('spot-shared');
        expect(visitCounts['Nolita'], equals(15));
        expect(visitCounts['East Village'], equals(15));

        // Spot remains in soft border spots list
        final updated = await boundaryService.getBoundary('Nolita', 'East Village');
        expect(updated?.softBorderSpots, contains('spot-shared'));
      });
    });

    group('Boundary Updates from User Behavior', () {
      test('should update boundary coordinates based on user movement', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-behavior',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Track user movements
        for (int i = 0; i < 50; i++) {
          await boundaryService.trackUserMovement('user-${i % 10}', 'spot-1', 'Nolita');
        }
        for (int i = 0; i < 10; i++) {
          await boundaryService.trackUserMovement('user-${i % 5}', 'spot-1', 'East Village');
        }

        // Analyze movement patterns
        final analysis = await boundaryService.analyzeMovementPatterns('Nolita', 'East Village');
        expect(analysis, isNotNull);

        // Update boundary from behavior
        await boundaryService.updateBoundaryFromBehavior('Nolita', 'East Village');

        // Verify boundary was updated
        final updated = await boundaryService.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
        expect(updated?.lastRefinedAt, isNotNull);
      });

      test('should track movement patterns for locality', () async {
        // Track movements for Nolita
        for (int i = 0; i < 30; i++) {
          await boundaryService.trackUserMovement('user-${i % 10}', 'spot-1', 'Nolita');
          await boundaryService.trackUserMovement('user-${i % 10}', 'spot-2', 'Nolita');
        }

        // Get movement patterns
        final patterns = await boundaryService.getUserMovementPatterns('Nolita');
        expect(patterns, isNotEmpty);
        expect(patterns['spot-1'], isNotNull);
        expect(patterns['spot-2'], isNotNull);
      });

      test('should calculate boundary changes from behavior', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-changes',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2'],
          userVisitCounts: {
            'spot-1': {'Nolita': 30, 'East Village': 5},
            'spot-2': {'Nolita': 4, 'East Village': 28},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Calculate changes
        final changes = await boundaryService.calculateBoundaryChanges('Nolita', 'East Village');
        expect(changes, isNotNull);
        expect(changes.isNotEmpty, isTrue);

        // Changes should reflect spot associations
        expect(changes.containsKey('spot-1'), isTrue);
        expect(changes.containsKey('spot-2'), isTrue);
      });
    });

    group('Integration with Geographic Hierarchy', () {
      test('should integrate boundaries with geographic hierarchy', () async {
        // Create boundaries for multiple localities
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'DUMBO',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary1);
        await boundaryService.saveBoundary(boundary2);

        // Integrate with hierarchy
        await boundaryService.integrateWithGeographicHierarchy('Greenpoint');

        // Verify boundaries are accessible
        final boundaries = await boundaryService.getBoundariesForLocality('Greenpoint');
        expect(boundaries, hasLength(2));
      });

      test('should update geographic hierarchy based on boundaries', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-hierarchy',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 25, 'East Village': 8},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Refine border
        await boundaryService.refineSoftBorder('Nolita', 'East Village');

        // Update hierarchy
        await boundaryService.updateGeographicHierarchy('Nolita');

        // Verify hierarchy reflects boundary changes
        final updated = await boundaryService.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
      });
    });

    group('Integration with Large City Detection', () {
      test('should work with large city neighborhoods', () async {
        // Verify Brooklyn is a large city
        expect(largeCityService.isLargeCity('Brooklyn'), isTrue);

        // Create boundary between Brooklyn neighborhoods
        final boundary = NeighborhoodBoundary(
          id: 'boundary-brooklyn',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Verify neighborhoods are recognized
        expect(largeCityService.isNeighborhoodLocality('Greenpoint'), isTrue);
        expect(largeCityService.isNeighborhoodLocality('Williamsburg'), isTrue);
        expect(largeCityService.getParentCity('Greenpoint'), equals('Brooklyn'));
        expect(largeCityService.getParentCity('Williamsburg'), equals('Brooklyn'));

        // Boundary should work with neighborhood localities
        final retrieved = await boundaryService.getBoundary('Greenpoint', 'Williamsburg');
        expect(retrieved, isNotNull);
        expect(retrieved?.locality1, equals('Greenpoint'));
        expect(retrieved?.locality2, equals('Williamsburg'));
      });

      test('should handle boundaries in multiple large cities', () async {
        // Brooklyn boundaries
        final brooklynBoundary = NeighborhoodBoundary(
          id: 'boundary-bk-1',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // LA boundaries (if LA neighborhoods exist)
        if (largeCityService.isLargeCity('Los Angeles')) {
          final laBoundary = NeighborhoodBoundary(
            id: 'boundary-la-1',
            locality1: 'Hollywood',
            locality2: 'Santa Monica',
            boundaryType: BoundaryType.hardBorder,
            coordinates: testCoordinates,
            source: 'Google Maps',
            createdAt: testDate,
            updatedAt: testDate,
          );

          await boundaryService.saveBoundary(laBoundary);

          expect(largeCityService.isNeighborhoodLocality('Hollywood'), isTrue);
          expect(largeCityService.isNeighborhoodLocality('Santa Monica'), isTrue);
        }

        await boundaryService.saveBoundary(brooklynBoundary);

        // Both boundaries should work independently
        final bkBoundary = await boundaryService.getBoundary('Greenpoint', 'Williamsburg');
        expect(bkBoundary, isNotNull);
      });
    });

    group('Complete Workflow Integration', () {
      test('should handle complete boundary lifecycle', () async {
        // Step 1: Load boundaries for large city
        final boundaries = await boundaryService.loadBoundariesFromGoogleMaps('Brooklyn');
        expect(boundaries, isA<List>());

        // Step 2: Create and save boundary
        final boundary = NeighborhoodBoundary(
          id: 'boundary-lifecycle',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await boundaryService.saveBoundary(boundary);

        // Step 3: Track user behavior
        for (int i = 0; i < 30; i++) {
          await boundaryService.trackSpotVisit('spot-1', 'Nolita');
          await boundaryService.trackUserMovement('user-${i % 10}', 'spot-1', 'Nolita');
        }

        // Step 4: Analyze and refine
        final shouldRefine = await boundaryService.shouldRefineBorder('Nolita', 'East Village');
        if (shouldRefine) {
          await boundaryService.refineSoftBorder('Nolita', 'East Village');
        }

        // Step 5: Update associations
        await boundaryService.updateSpotLocalityAssociation('spot-1');

        // Step 6: Integrate with hierarchy
        await boundaryService.integrateWithGeographicHierarchy('Nolita');
        await boundaryService.updateGeographicHierarchy('Nolita');

        // Step 7: Verify complete workflow
        final finalBoundary = await boundaryService.getBoundary('Nolita', 'East Village');
        expect(finalBoundary, isNotNull);
        expect(finalBoundary?.refinementHistory, isNotEmpty);
        expect(finalBoundary?.userVisitCounts['spot-1']?['Nolita'], equals(30));

        final association = await boundaryService.getSpotLocalityAssociation('spot-1');
        expect(association, equals('Nolita'));
      });
    });
  });
}

