import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/brand_discovery.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BrandDiscovery model
void main() {
  group('BrandDiscovery Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test('should create brand discovery with required fields', () {
      final discovery = BrandDiscovery(
        id: 'discovery-123',
        eventId: 'event-456',
        searchCriteria: {'category': 'Food & Beverage'},
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(discovery.id, equals('discovery-123'));
      expect(discovery.eventId, equals('event-456'));
      expect(discovery.matchCount, equals(0));
      expect(discovery.hasViableMatches, isFalse);
    });

    test('should filter viable matches above 70% threshold', () {
      final match1 = BrandMatch(
        brandId: 'brand-1',
        brandName: 'Brand 1',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85.0,
          valueAlignment: 90.0,
          styleCompatibility: 80.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
      );

      final match2 = BrandMatch(
        brandId: 'brand-2',
        brandName: 'Brand 2',
        compatibilityScore: 65.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 65.0,
          valueAlignment: 70.0,
          styleCompatibility: 60.0,
          qualityFocus: 65.0,
          audienceAlignment: 65.0,
        ),
      );

      final discovery = BrandDiscovery(
        id: 'discovery-123',
        eventId: 'event-456',
        searchCriteria: {'category': 'Food & Beverage'},
        matchingResults: [match1, match2],
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(discovery.matchCount, equals(2));
      expect(discovery.highCompatibilityMatches, equals(1));
      expect(discovery.hasViableMatches, isTrue);
      expect(discovery.viableMatches.length, equals(1));
      expect(discovery.viableMatches.first.brandId, equals('brand-1'));
    });

    test('should serialize and deserialize correctly', () {
      final match = BrandMatch(
        brandId: 'brand-1',
        brandName: 'Brand 1',
        compatibilityScore: 85.0,
        vibeCompatibility: VibeCompatibility(
          overallScore: 85.0,
          valueAlignment: 90.0,
          styleCompatibility: 80.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
        ),
      );

      final discovery = BrandDiscovery(
        id: 'discovery-123',
        eventId: 'event-456',
        searchCriteria: {'category': 'Food & Beverage'},
        matchingResults: [match],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = discovery.toJson();
      final restored = BrandDiscovery.fromJson(json);

      expect(restored.id, equals(discovery.id));
      expect(restored.matchCount, equals(1));
      expect(restored.matchingResults.first.compatibilityScore, equals(85.0));
    });
  });
}

