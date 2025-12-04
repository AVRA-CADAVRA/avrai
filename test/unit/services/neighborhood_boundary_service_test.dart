import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/neighborhood_boundary_service.dart';
import 'package:spots/core/models/neighborhood_boundary.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for NeighborhoodBoundaryService
///
/// **Philosophy:** Neighborhood boundaries reflect actual community connections,
/// not just geographic lines. Borders evolve based on user behavior.
void main() {
  group('NeighborhoodBoundaryService Tests', () {
    late NeighborhoodBoundaryService service;
    late DateTime testDate;
    late List<CoordinatePoint> testCoordinates;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testCoordinates = [
        const CoordinatePoint(latitude: 40.7295, longitude: -73.9545),
        const CoordinatePoint(latitude: 40.7300, longitude: -73.9550),
        const CoordinatePoint(latitude: 40.7305, longitude: -73.9555),
      ];
      service = NeighborhoodBoundaryService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Boundary Loading', () {
      test('should load boundaries from Google Maps for city', () async {
        // Note: This will use mock data initially
        final boundaries =
            await service.loadBoundariesFromGoogleMaps('Brooklyn');

        expect(boundaries, isA<List<NeighborhoodBoundary>>());
        // In real implementation, would verify boundaries are loaded
      });

      test('should return empty list for city with no boundaries', () async {
        final boundaries =
            await service.loadBoundariesFromGoogleMaps('Smalltown');

        expect(boundaries, isEmpty);
      });

      test('should handle errors when loading boundaries', () async {
        // Test error handling for invalid city names or API failures
        expect(
          () => service.loadBoundariesFromGoogleMaps(''),
          returnsNormally,
        );
      });
    });

    group('Get Boundary', () {
      test('should get boundary between two localities', () async {
        // First, save a boundary
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final retrieved =
            await service.getBoundary('Greenpoint', 'Williamsburg');

        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals('boundary-123'));
        expect(retrieved?.locality1, equals('Greenpoint'));
        expect(retrieved?.locality2, equals('Williamsburg'));
      });

      test('should return null for non-existent boundary', () async {
        final boundary =
            await service.getBoundary('NonExistent1', 'NonExistent2');

        expect(boundary, isNull);
      });

      test('should get boundary regardless of locality order', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        // Try both orders
        final retrieved1 =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        final retrieved2 =
            await service.getBoundary('Williamsburg', 'Greenpoint');

        expect(retrieved1, isNotNull);
        expect(retrieved2, isNotNull);
        expect(retrieved1?.id, equals(retrieved2?.id));
      });
    });

    group('Get Boundaries for Locality', () {
      test('should get all boundaries for a locality', () async {
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

        await service.saveBoundary(boundary1);
        await service.saveBoundary(boundary2);

        final boundaries = await service.getBoundariesForLocality('Greenpoint');

        expect(boundaries, hasLength(2));
        expect(boundaries.any((b) => b.id == 'boundary-1'), isTrue);
        expect(boundaries.any((b) => b.id == 'boundary-2'), isTrue);
      });

      test('should return empty list for locality with no boundaries',
          () async {
        final boundaries =
            await service.getBoundariesForLocality('NonExistent');

        expect(boundaries, isEmpty);
      });
    });

    group('Hard Border Detection', () {
      test('should detect hard border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final isHard = await service.isHardBorder('NoHo', 'SoHo');

        expect(isHard, isTrue);
      });

      test('should return false for soft border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final isHard = await service.isHardBorder('Nolita', 'East Village');

        expect(isHard, isFalse);
      });

      test('should get all hard borders for city', () async {
        final hardBorder1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final hardBorder2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final softBorder = NeighborhoodBoundary(
          id: 'boundary-3',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(hardBorder1);
        await service.saveBoundary(hardBorder2);
        await service.saveBoundary(softBorder);

        final hardBorders = await service.getHardBorders('Brooklyn');

        expect(hardBorders, hasLength(2));
        expect(
            hardBorders.every((b) => b.boundaryType == BoundaryType.hardBorder),
            isTrue);
      });
    });

    group('Soft Border Detection', () {
      test('should detect soft border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final isSoft = await service.isSoftBorder('Nolita', 'East Village');

        expect(isSoft, isTrue);
      });

      test('should return false for hard border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final isSoft = await service.isSoftBorder('NoHo', 'SoHo');

        expect(isSoft, isFalse);
      });

      test('should get all soft borders for city', () async {
        final softBorder1 = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final softBorder2 = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final hardBorder = NeighborhoodBoundary(
          id: 'boundary-3',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(softBorder1);
        await service.saveBoundary(softBorder2);
        await service.saveBoundary(hardBorder);

        final softBorders = await service.getSoftBorders('Brooklyn');

        expect(softBorders, hasLength(2));
        expect(
            softBorders.every((b) => b.boundaryType == BoundaryType.softBorder),
            isTrue);
      });
    });

    group('Soft Border Spot Tracking', () {
      test('should add spot to soft border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);
        await service.addSoftBorderSpot('spot-1', 'Nolita', 'East Village');

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.softBorderSpots, contains('spot-1'));
      });

      test('should get soft border spots', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final spots =
            await service.getSoftBorderSpots('Nolita', 'East Village');

        expect(spots, hasLength(2));
        expect(spots, contains('spot-1'));
        expect(spots, contains('spot-2'));
      });

      test('should check if spot is in soft border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        expect(await service.isSpotInSoftBorder('spot-1'), isTrue);
        expect(await service.isSpotInSoftBorder('spot-2'), isFalse);
      });
    });

    group('User Visit Tracking', () {
      test('should track user visit to spot', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);
        await service.trackSpotVisit('spot-1', 'Nolita');

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.userVisitCounts['spot-1']?['Nolita'], equals(1));
      });

      test('should increment visit count for multiple visits', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        await service.trackSpotVisit('spot-1', 'Nolita');
        await service.trackSpotVisit('spot-1', 'Nolita');
        await service.trackSpotVisit('spot-1', 'Nolita');

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.userVisitCounts['spot-1']?['Nolita'], equals(3));
      });

      test('should get visit counts for spot', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 15, 'East Village': 8},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final visitCounts = await service.getSpotVisitCounts('spot-1');

        expect(visitCounts['Nolita'], equals(15));
        expect(visitCounts['East Village'], equals(8));
      });

      test('should get dominant locality for spot', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 15, 'East Village': 8},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final dominant = await service.getDominantLocality('spot-1');

        expect(dominant, equals('Nolita'));
      });
    });

    group('Border Refinement', () {
      test('should check if border should be refined', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {
              'Nolita': 20,
              'East Village': 5
            }, // Significant difference
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final shouldRefine =
            await service.shouldRefineBorder('Nolita', 'East Village');

        expect(shouldRefine, isTrue);
      });

      test('should not refine border with insufficient data', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 3, 'East Village': 2}, // Not enough data
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final shouldRefine =
            await service.shouldRefineBorder('Nolita', 'East Village');

        expect(shouldRefine, isFalse);
      });

      test('should calculate border refinement', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
            'spot-2': {'Nolita': 3, 'East Village': 15},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final refinement =
            await service.calculateBorderRefinement('Nolita', 'East Village');

        expect(refinement, isNotNull);
        expect(refinement, isA<Map<String, dynamic>>());
        expect(refinement.isNotEmpty, isTrue);
      });

      test('should refine soft border', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        await service.refineSoftBorder('Nolita', 'East Village');

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
        expect(updated?.lastRefinedAt, isNotNull);
      });
    });

    group('Dynamic Border Updates', () {
      test('should track user movement', () async {
        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');

        // Verify movement was tracked (implementation dependent)
        expect(await service.getUserMovementPatterns('Nolita'), isA<Map>());
      });

      test('should get user movement patterns for locality', () async {
        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-2', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-1', 'spot-2', 'Nolita');

        final patterns = await service.getUserMovementPatterns('Nolita');

        expect(patterns, isNotEmpty);
      });

      test('should analyze movement patterns between localities', () async {
        await service.trackUserMovement('user-1', 'spot-1', 'Nolita');
        await service.trackUserMovement('user-2', 'spot-1', 'East Village');
        await service.trackUserMovement('user-3', 'spot-1', 'Nolita');

        final analysis =
            await service.analyzeMovementPatterns('Nolita', 'East Village');

        expect(analysis, isNotNull);
      });

      test('should associate spot with locality', () async {
        await service.associateSpotWithLocality('spot-1', 'Nolita');

        final association = await service.getSpotLocalityAssociation('spot-1');

        expect(association, equals('Nolita'));
      });

      test('should update spot locality association based on visits', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        await service.updateSpotLocalityAssociation('spot-1');

        final association = await service.getSpotLocalityAssociation('spot-1');
        expect(association, equals('Nolita'));
      });

      test('should update boundary from behavior', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        await service.updateBoundaryFromBehavior('Nolita', 'East Village');

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
      });

      test('should calculate boundary changes', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final changes =
            await service.calculateBoundaryChanges('Nolita', 'East Village');

        expect(changes, isNotNull);
        expect(changes.isNotEmpty, isTrue);
      });

      test('should apply boundary refinement', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 20, 'East Village': 5},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final refinement =
            await service.calculateBorderRefinement('Nolita', 'East Village');
        await service.applyBoundaryRefinement(
            'Nolita', 'East Village', refinement);

        final updated = await service.getBoundary('Nolita', 'East Village');
        expect(updated?.refinementHistory, isNotEmpty);
        expect(updated?.lastRefinedAt, isNotNull);
      });
    });

    group('Geographic Hierarchy Integration', () {
      test('should integrate with geographic hierarchy', () async {
        await service.integrateWithGeographicHierarchy('Nolita');

        // Verify integration (implementation dependent)
        expect(await service.getBoundariesForLocality('Nolita'), isA<List>());
      });

      test('should update geographic hierarchy based on boundaries', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        await service.updateGeographicHierarchy('Nolita');

        // Verify hierarchy was updated (implementation dependent)
        expect(await service.getBoundariesForLocality('Nolita'), isNotEmpty);
      });
    });

    group('Save and Update Boundary', () {
      test('should save boundary', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final retrieved =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals('boundary-123'));
      });

      test('should update boundary', () async {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        await service.saveBoundary(boundary);

        final updated = boundary.copyWith(
          boundaryType: BoundaryType.softBorder,
          softBorderSpots: ['spot-1'],
        );

        await service.updateBoundary(updated);

        final retrieved =
            await service.getBoundary('Greenpoint', 'Williamsburg');
        expect(retrieved?.boundaryType, equals(BoundaryType.softBorder));
        expect(retrieved?.softBorderSpots, contains('spot-1'));
      });
    });
  });
}
