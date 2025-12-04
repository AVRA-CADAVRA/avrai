import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/sponsorship_integration.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Brand Discovery Flow Integration Tests
/// 
/// Agent 3: Models & Testing (Week 12)
/// 
/// Tests the complete brand discovery flow:
/// - Brand searches for events to sponsor
/// - Event search with filters
/// - Vibe-based matching (70%+ threshold)
/// - Compatibility scoring
/// - Match filtering and ranking
/// 
/// **Test Scenarios:**
/// - Scenario 1: Brand Searches for Events
/// - Scenario 2: Vibe Matching and Filtering
/// - Scenario 3: Compatibility Scoring
/// - Scenario 4: Match Ranking and Selection
void main() {
  group('Brand Discovery Flow Integration Tests', () {
    late DateTime testDate;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late BrandAccount testBrand;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Expert User',
      );
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: testDate,
        updatedAt: testDate,
        createdBy: 'user-123',
      );
      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Scenario 1: Brand Searches for Events', () {
      test('should create brand discovery with search criteria', () {
        // Arrange
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final discovery = BrandDiscovery(
          id: 'discovery-123',
          eventId: 'event-456',
          searchCriteria: {
            'category': 'Food & Beverage',
            'location': 'Brooklyn',
            'minAttendees': 20,
            'eventType': 'dinner',
            'dateRange': {
              'start': testDate.toIso8601String(),
              'end': testDate.add(Duration(days: 30)).toIso8601String(),
            },
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act & Assert
        expect(discovery.eventId, equals(partnership.eventId));
        expect(discovery.searchCriteria['category'], equals('Food & Beverage'));
        expect(discovery.matchCount, equals(0));
      });

      test('should filter events by search criteria', () {
        // Arrange
        final discoveries = [
          BrandDiscovery(
            id: 'discovery-1',
            eventId: 'event-1',
            searchCriteria: {
              'category': 'Food & Beverage',
              'minAttendees': 20,
            },
            createdAt: testDate,
            updatedAt: testDate,
          ),
          BrandDiscovery(
            id: 'discovery-2',
            eventId: 'event-2',
            searchCriteria: {
              'category': 'Technology',
              'minAttendees': 50,
            },
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        // Act
        final foodEvents = discoveries
            .where((d) => d.searchCriteria['category'] == 'Food & Beverage')
            .toList();

        // Assert
        expect(foodEvents.length, equals(1));
        expect(foodEvents.first.eventId, equals('event-1'));
      });
    });

    group('Scenario 2: Vibe Matching and Filtering', () {
      test('should match brands with 70%+ compatibility', () {
        // Arrange
        final highMatch = BrandMatch(
          brandId: 'brand-1',
          brandName: 'Premium Oil Co.',
          compatibilityScore: 85.0,
          vibeCompatibility: VibeCompatibility(
            overallScore: 85.0,
            valueAlignment: 90.0,
            styleCompatibility: 80.0,
            qualityFocus: 85.0,
            audienceAlignment: 85.0,
          ),
          matchReasons: ['Value alignment', 'Quality focus'],
        );

        final lowMatch = BrandMatch(
          brandId: 'brand-2',
          brandName: 'Generic Brand',
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
          matchingResults: [highMatch, lowMatch],
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final viableMatches = discovery.viableMatches;

        // Assert
        expect(discovery.hasViableMatches, isTrue);
        expect(viableMatches.length, equals(1));
        expect(viableMatches.first.compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(viableMatches.first.meetsThreshold, isTrue);
      });

      test('should filter out matches below 70% threshold', () {
        // Arrange
        final matches = [
          BrandMatch(
            brandId: 'brand-1',
            brandName: 'Brand 1',
            compatibilityScore: 75.0,
            vibeCompatibility: VibeCompatibility(
              overallScore: 75.0,
              valueAlignment: 80.0,
              styleCompatibility: 70.0,
              qualityFocus: 75.0,
              audienceAlignment: 75.0,
            ),
          ),
          BrandMatch(
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
          ),
          BrandMatch(
            brandId: 'brand-3',
            brandName: 'Brand 3',
            compatibilityScore: 55.0,
            vibeCompatibility: VibeCompatibility(
              overallScore: 55.0,
              valueAlignment: 60.0,
              styleCompatibility: 50.0,
              qualityFocus: 55.0,
              audienceAlignment: 55.0,
            ),
          ),
        ];

        final discovery = BrandDiscovery(
          id: 'discovery-123',
          eventId: 'event-456',
          searchCriteria: {'category': 'Food & Beverage'},
          matchingResults: matches,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final viableMatches = discovery.viableMatches;

        // Assert
        expect(discovery.matchCount, equals(3));
        expect(discovery.highCompatibilityMatches, equals(1));
        expect(viableMatches.length, equals(1));
        expect(viableMatches.first.brandId, equals('brand-1'));
      });
    });

    group('Scenario 3: Compatibility Scoring', () {
      test('should calculate comprehensive compatibility scores', () {
        // Arrange
        final vibeCompatibility = VibeCompatibility(
          overallScore: 85.0,
          valueAlignment: 90.0,
          styleCompatibility: 80.0,
          qualityFocus: 85.0,
          audienceAlignment: 85.0,
          breakdown: {
            'values': 90.0,
            'style': 80.0,
            'quality': 85.0,
            'audience': 85.0,
            'communication': 85.0,
          },
        );

        final match = BrandMatch(
          brandId: 'brand-123',
          brandName: 'Premium Oil Co.',
          compatibilityScore: 85.0,
          vibeCompatibility: vibeCompatibility,
          matchReasons: [
            'Strong value alignment',
            'Quality focus matches',
            'Audience compatibility',
          ],
        );

        // Act & Assert
        expect(match.compatibilityScore, equals(85.0));
        expect(match.vibeCompatibility.overallScore, equals(85.0));
        expect(match.vibeCompatibility.meetsThreshold, isTrue);
        expect(match.meetsThreshold, isTrue);
        expect(match.matchReasons.length, equals(3));
      });

      test('should rank matches by compatibility score', () {
        // Arrange
        final matches = [
          BrandMatch(
            brandId: 'brand-1',
            brandName: 'Brand 1',
            compatibilityScore: 75.0,
            vibeCompatibility: VibeCompatibility(
              overallScore: 75.0,
              valueAlignment: 80.0,
              styleCompatibility: 70.0,
              qualityFocus: 75.0,
              audienceAlignment: 75.0,
            ),
          ),
          BrandMatch(
            brandId: 'brand-2',
            brandName: 'Brand 2',
            compatibilityScore: 90.0,
            vibeCompatibility: VibeCompatibility(
              overallScore: 90.0,
              valueAlignment: 95.0,
              styleCompatibility: 85.0,
              qualityFocus: 90.0,
              audienceAlignment: 90.0,
            ),
          ),
          BrandMatch(
            brandId: 'brand-3',
            brandName: 'Brand 3',
            compatibilityScore: 80.0,
            vibeCompatibility: VibeCompatibility(
              overallScore: 80.0,
              valueAlignment: 85.0,
              styleCompatibility: 75.0,
              qualityFocus: 80.0,
              audienceAlignment: 80.0,
            ),
          ),
        ];

        final discovery = BrandDiscovery(
          id: 'discovery-123',
          eventId: 'event-456',
          searchCriteria: {'category': 'Food & Beverage'},
          matchingResults: matches,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final rankedMatches = discovery.viableMatches;

        // Assert
        expect(rankedMatches.length, equals(3));
        expect(rankedMatches.first.compatibilityScore, equals(90.0));
        expect(rankedMatches[1].compatibilityScore, equals(80.0));
        expect(rankedMatches.last.compatibilityScore, equals(75.0));
      });
    });

    group('Scenario 4: Match Ranking and Selection', () {
      test('should get discovery for event with viable matches', () {
        // Arrange
        final match = BrandMatch(
          brandId: 'brand-123',
          brandName: 'Premium Oil Co.',
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

        final discoveries = [discovery];

        // Act
        final eventDiscovery = SponsorshipIntegration.getDiscoveryForEvent(
          'event-456',
          discoveries,
        );
        final viableMatches = SponsorshipIntegration.getViableBrandMatches(
          'event-456',
          discoveries,
        );
        final hasMatches = SponsorshipIntegration.hasDiscoveryMatches(
          'event-456',
          discoveries,
        );

        // Assert
        expect(eventDiscovery, isNotNull);
        expect(viableMatches.length, equals(1));
        expect(hasMatches, isTrue);
      });

      test('should handle events with no viable matches', () {
        // Arrange
        final lowMatch = BrandMatch(
          brandId: 'brand-123',
          brandName: 'Brand',
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
          matchingResults: [lowMatch],
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Act
        final viableMatches = discovery.viableMatches;

        // Assert
        expect(discovery.hasViableMatches, isFalse);
        expect(viableMatches.length, equals(0));
      });
    });
  });
}

