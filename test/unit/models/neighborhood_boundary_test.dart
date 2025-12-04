import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/neighborhood_boundary.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for NeighborhoodBoundary model
/// 
/// **Philosophy:** Neighborhood boundaries reflect actual community connections,
/// not just geographic lines. Borders evolve based on user behavior.
void main() {
  group('NeighborhoodBoundary Model Tests', () {
    late DateTime testDate;
    late List<CoordinatePoint> testCoordinates;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testCoordinates = const [
        CoordinatePoint(latitude: 40.7295, longitude: -73.9545),
        CoordinatePoint(latitude: 40.7300, longitude: -73.9550),
        CoordinatePoint(latitude: 40.7305, longitude: -73.9555),
      ];
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create boundary with required fields', () {
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

        expect(boundary.id, equals('boundary-123'));
        expect(boundary.locality1, equals('Greenpoint'));
        expect(boundary.locality2, equals('Williamsburg'));
        expect(boundary.boundaryType, equals(BoundaryType.hardBorder));
        expect(boundary.coordinates, equals(testCoordinates));
        expect(boundary.source, equals('Google Maps'));
        expect(boundary.softBorderSpots, isEmpty);
        expect(boundary.userVisitCounts, isEmpty);
        expect(boundary.refinementHistory, isEmpty);
        expect(boundary.lastRefinedAt, isNull);
      });

      test('should create soft border boundary', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2'],
          userVisitCounts: {
            'spot-1': {'Nolita': 10, 'East Village': 5},
            'spot-2': {'Nolita': 3, 'East Village': 8},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.boundaryType, equals(BoundaryType.softBorder));
        expect(boundary.softBorderSpots, equals(['spot-1', 'spot-2']));
        expect(boundary.userVisitCounts['spot-1']?['Nolita'], equals(10));
        expect(boundary.userVisitCounts['spot-2']?['East Village'], equals(8));
      });

      test('should create boundary with refinement history', () {
        final refinement1 = RefinementEvent(
          timestamp: testDate,
          reason: 'User behavior analysis',
          method: 'Visit count analysis',
          changes: 'Moved spot-1 to Nolita',
        );
        final refinement2 = RefinementEvent(
          timestamp: TestHelpers.createTimestampWithOffset(const Duration(days: 1)),
          reason: 'Visit count threshold reached',
          method: 'Threshold analysis',
          changes: 'Moved spot-2 to East Village',
        );

        final boundary = NeighborhoodBoundary(
          id: 'boundary-789',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          refinementHistory: [refinement1, refinement2],
          lastRefinedAt: TestHelpers.createTimestampWithOffset(const Duration(days: 1)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.refinementHistory, hasLength(2));
        expect(boundary.refinementHistory[0].reason, equals('User behavior analysis'));
        expect(boundary.lastRefinedAt, isNotNull);
      });
    });

    group('Boundary Type Enum', () {
      test('should have hardBorder and softBorder values', () {
        expect(BoundaryType.hardBorder, isNotNull);
        expect(BoundaryType.softBorder, isNotNull);
      });

      test('should correctly identify hard border', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.boundaryType, equals(BoundaryType.hardBorder));
        expect(boundary.isHardBorder, isTrue);
        expect(boundary.isSoftBorder, isFalse);
      });

      test('should correctly identify soft border', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.boundaryType, equals(BoundaryType.softBorder));
        expect(boundary.isHardBorder, isFalse);
        expect(boundary.isSoftBorder, isTrue);
      });
    });

    group('Coordinate Storage', () {
      test('should store multiple coordinate points', () {
        final manyCoordinates = List.generate(10, (i) => CoordinatePoint(
          latitude: 40.7295 + (i * 0.001),
          longitude: -73.9545 - (i * 0.001),
        ));

        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: manyCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.coordinates, hasLength(10));
        expect(boundary.coordinates[0].latitude, equals(40.7295));
        expect(boundary.coordinates[9].latitude, equals(40.7295 + 0.009));
      });

      test('should handle empty coordinates', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: [],
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.coordinates, isEmpty);
      });
    });

    group('Soft Border Spot Tracking', () {
      test('should track spots in soft border areas', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2', 'spot-3'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.softBorderSpots, hasLength(3));
        expect(boundary.softBorderSpots, contains('spot-1'));
        expect(boundary.softBorderSpots, contains('spot-2'));
        expect(boundary.softBorderSpots, contains('spot-3'));
      });

      test('should check if spot is in soft border', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1', 'spot-2'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.isSpotInSoftBorder('spot-1'), isTrue);
        expect(boundary.isSpotInSoftBorder('spot-2'), isTrue);
        expect(boundary.isSpotInSoftBorder('spot-3'), isFalse);
      });
    });

    group('User Visit Count Tracking', () {
      test('should track visit counts by locality', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
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

        expect(boundary.userVisitCounts['spot-1']?['Nolita'], equals(15));
        expect(boundary.userVisitCounts['spot-1']?['East Village'], equals(8));
      });

      test('should get visit counts for spot', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
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

        final visitCounts = boundary.userVisitCounts['spot-1'];
        expect(visitCounts?['Nolita'], equals(15));
        expect(visitCounts?['East Village'], equals(8));
        expect(boundary.userVisitCounts['spot-2'], isNull);
      });

      test('should get dominant locality for spot', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
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

        expect(boundary.getDominantLocality('spot-1'), equals('Nolita'));
      });

      test('should handle tie in visit counts', () {
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Nolita': 10, 'East Village': 10},
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // In case of tie, should return locality1 (first locality)
        expect(boundary.getDominantLocality('spot-1'), equals('Nolita'));
      });
    });

    group('Refinement History', () {
      test('should track refinement events', () {
        final refinement1 = RefinementEvent(
          timestamp: testDate,
          reason: 'User behavior analysis',
          method: 'Visit count analysis',
          changes: 'Moved spot-1 to Nolita',
        );
        final refinement2 = RefinementEvent(
          timestamp: TestHelpers.createTimestampWithOffset(const Duration(days: 1)),
          reason: 'Visit count threshold reached',
          method: 'Threshold analysis',
          changes: 'Moved spot-2 to East Village',
        );

        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          refinementHistory: [refinement1, refinement2],
          lastRefinedAt: TestHelpers.createTimestampWithOffset(const Duration(days: 1)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.refinementHistory, hasLength(2));
        expect(boundary.refinementHistory[0].reason, equals('User behavior analysis'));
        expect(boundary.refinementHistory[1].reason, equals('Visit count threshold reached'));
        expect(boundary.refinementHistory[0].changes, equals('Moved spot-1 to Nolita'));
        expect(boundary.refinementHistory[1].changes, equals('Moved spot-2 to East Village'));
      });

      test('should track last refinement timestamp', () {
        final lastRefined = TestHelpers.createTimestampWithOffset(const Duration(days: 5));
        final boundary = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          lastRefinedAt: lastRefined,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary.lastRefinedAt, equals(lastRefined));
        expect(boundary.lastRefinedAt, isNotNull);
      });

      test('should indicate if boundary has been refined', () {
        final unrefined = NeighborhoodBoundary(
          id: 'boundary-1',
          locality1: 'NoHo',
          locality2: 'SoHo',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(unrefined.lastRefinedAt, isNull);

        final refined = NeighborhoodBoundary(
          id: 'boundary-2',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          lastRefinedAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(refined.lastRefinedAt, isNotNull);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final refinement = RefinementEvent(
          timestamp: testDate,
          reason: 'User behavior',
          method: 'Visit count analysis',
          changes: 'Moved spot-1',
        );

        final boundary = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          userVisitCounts: {
            'spot-1': {'Greenpoint': 10, 'Williamsburg': 5},
          },
          refinementHistory: [refinement],
          lastRefinedAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = boundary.toJson();

        expect(json['id'], equals('boundary-123'));
        expect(json['locality1'], equals('Greenpoint'));
        expect(json['locality2'], equals('Williamsburg'));
        expect(json['boundaryType'], equals('hardBorder'));
        expect(json['coordinates'], isA<List>());
        expect(json['source'], equals('Google Maps'));
        expect(json['softBorderSpots'], equals(['spot-1']));
        expect(json['userVisitCounts'], isA<Map>());
        expect(json['refinementHistory'], isA<List>());
        expect(json['lastRefinedAt'], equals(testDate.toIso8601String()));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON', () {
        final refinementJson = {
          'timestamp': testDate.toIso8601String(),
          'reason': 'User behavior',
          'method': 'Visit count analysis',
          'changes': 'Moved spot-1',
        };

        final json = {
          'id': 'boundary-123',
          'locality1': 'Greenpoint',
          'locality2': 'Williamsburg',
          'boundaryType': 'hardBorder',
          'coordinates': testCoordinates,
          'source': 'Google Maps',
          'softBorderSpots': ['spot-1'],
          'userVisitCounts': {
            'spot-1': {'Greenpoint': 10, 'Williamsburg': 5},
          },
          'refinementHistory': [refinementJson],
          'lastRefinedAt': testDate.toIso8601String(),
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final boundary = NeighborhoodBoundary.fromJson(json);

        expect(boundary.id, equals('boundary-123'));
        expect(boundary.locality1, equals('Greenpoint'));
        expect(boundary.locality2, equals('Williamsburg'));
        expect(boundary.boundaryType, equals(BoundaryType.hardBorder));
        expect(boundary.coordinates, equals(testCoordinates));
        expect(boundary.source, equals('Google Maps'));
        expect(boundary.softBorderSpots, equals(['spot-1']));
        expect(boundary.userVisitCounts['spot-1']?['Greenpoint'], equals(10));
        expect(boundary.refinementHistory, hasLength(1));
        expect(boundary.lastRefinedAt, equals(testDate));
      });

      test('should handle missing optional fields in JSON', () {
        final json = {
          'id': 'boundary-123',
          'locality1': 'Greenpoint',
          'locality2': 'Williamsburg',
          'boundaryType': 'hardBorder',
          'coordinates': testCoordinates,
          'source': 'Google Maps',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final boundary = NeighborhoodBoundary.fromJson(json);

        expect(boundary.softBorderSpots, isEmpty);
        expect(boundary.userVisitCounts, isEmpty);
        expect(boundary.refinementHistory, isEmpty);
        expect(boundary.lastRefinedAt, isNull);
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated fields', () {
        final original = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          boundaryType: BoundaryType.softBorder,
          softBorderSpots: ['spot-1'],
          lastRefinedAt: testDate,
        );

        expect(updated.id, equals(original.id));
        expect(updated.locality1, equals(original.locality1));
        expect(updated.locality2, equals(original.locality2));
        expect(updated.boundaryType, equals(BoundaryType.softBorder));
        expect(updated.softBorderSpots, equals(['spot-1']));
        expect(updated.lastRefinedAt, equals(testDate));
      });

      test('should preserve original values when fields not specified', () {
        final original = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          softBorderSpots: ['spot-1'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(boundaryType: BoundaryType.softBorder);

        expect(updated.softBorderSpots, equals(original.softBorderSpots));
        expect(updated.coordinates, equals(original.coordinates));
        expect(updated.source, equals(original.source));
      });

      test('should create copy without changing original', () {
        final original = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final copy = original.copyWith(boundaryType: BoundaryType.softBorder);

        expect(original.boundaryType, equals(BoundaryType.hardBorder));
        expect(copy.boundaryType, equals(BoundaryType.softBorder));
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary1, equals(boundary2));
        expect(boundary1.hashCode, equals(boundary2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final boundary1 = NeighborhoodBoundary(
          id: 'boundary-123',
          locality1: 'Greenpoint',
          locality2: 'Williamsburg',
          boundaryType: BoundaryType.hardBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final boundary2 = NeighborhoodBoundary(
          id: 'boundary-456',
          locality1: 'Nolita',
          locality2: 'East Village',
          boundaryType: BoundaryType.softBorder,
          coordinates: testCoordinates,
          source: 'Google Maps',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(boundary1, isNot(equals(boundary2)));
      });
    });
  });

  group('RefinementEvent Model Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = TestHelpers.createTestDateTime();
    });

    test('should create refinement event', () {
      final event = RefinementEvent(
        timestamp: testDate,
        reason: 'User behavior analysis',
        method: 'Visit count analysis',
        changes: 'Moved spot-1 to Nolita',
      );

      expect(event.timestamp, equals(testDate));
      expect(event.reason, equals('User behavior analysis'));
      expect(event.method, equals('Visit count analysis'));
      expect(event.changes, equals('Moved spot-1 to Nolita'));
    });

    test('should serialize refinement event to JSON', () {
      final event = RefinementEvent(
        timestamp: testDate,
        reason: 'User behavior',
        method: 'Visit count analysis',
        changes: 'Moved spot-1',
      );

      final json = event.toJson();

      expect(json['timestamp'], equals(testDate.toIso8601String()));
      expect(json['reason'], equals('User behavior'));
      expect(json['method'], equals('Visit count analysis'));
      expect(json['changes'], equals('Moved spot-1'));
    });

    test('should deserialize refinement event from JSON', () {
      final json = {
        'timestamp': testDate.toIso8601String(),
        'reason': 'User behavior',
        'method': 'Visit count analysis',
        'changes': 'Moved spot-1',
      };

      final event = RefinementEvent.fromJson(json);

      expect(event.timestamp, equals(testDate));
      expect(event.reason, equals('User behavior'));
      expect(event.method, equals('Visit count analysis'));
      expect(event.changes, equals('Moved spot-1'));
    });
  });
}

