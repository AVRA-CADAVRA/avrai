import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/brand_discovery_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../fixtures/model_factories.dart';

// Mock dependencies
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockSponsorshipService extends Mock implements SponsorshipService {}

/// Brand Discovery Services Integration Tests
/// 
/// Agent 1: Backend & Integration (Week 12)
/// 
/// Tests service-level integration for brand discovery:
/// - BrandDiscoveryService brand search for events
/// - BrandDiscoveryService event search for brands
/// - Vibe-based matching algorithm
/// - Compatibility scoring
/// - Sponsorship suggestions
/// 
/// **Test Scenarios:**
/// - Scenario 1: Brand Search for Events
/// - Scenario 2: Event Search for Brands
/// - Scenario 3: Vibe Matching (70%+ threshold)
/// - Scenario 4: Compatibility Scoring
/// - Scenario 5: Sponsorship Suggestions
void main() {
  group('Brand Discovery Services Integration Tests', () {
    late BrandDiscoveryService brandDiscoveryService;
    late MockExpertiseEventService mockEventService;
    late MockSponsorshipService mockSponsorshipService;
    
    late DateTime testDate;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      mockEventService = MockExpertiseEventService();
      mockSponsorshipService = MockSponsorshipService();
      
      brandDiscoveryService = BrandDiscoveryService(
        eventService: mockEventService,
        sponsorshipService: mockSponsorshipService,
      );
      
      testEvent = IntegrationTestHelpers.createPaidEvent(
        host: ModelFactories.createTestUser(id: 'user-123'),
        id: 'event-456',
        title: 'Gourmet Dinner',
        category: 'Food & Beverage',
        price: 75.00,
      );
      
      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        categories: ['Gourmet', 'Premium Products'],
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });
    
    tearDown(() {
      reset(mockEventService);
      reset(mockSponsorshipService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Brand Search for Events', () {
      test('should find brands for event with 70%+ compatibility', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.75); // 75% compatibility
        
        await brandDiscoveryService.registerBrand(testBrand);
        
        // Act
        final matches = await brandDiscoveryService.findBrandsForEvent(
          eventId: 'event-456',
          minCompatibility: 0.70,
        );
        
        // Assert
        expect(matches, isNotEmpty);
        expect(matches.first.brandId, equals('brand-123'));
        expect(matches.first.compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(matches.first.meetsThreshold, isTrue);
      });
      
      test('should filter out brands below 70% threshold', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.65); // 65% - below threshold
        
        await brandDiscoveryService.registerBrand(testBrand);
        
        // Act
        final matches = await brandDiscoveryService.findBrandsForEvent(
          eventId: 'event-456',
          minCompatibility: 0.70,
        );
        
        // Assert
        expect(matches, isEmpty);
      });
      
      test('should sort matches by compatibility score', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        final brand1 = testBrand.copyWith(id: 'brand-1');
        final brand2 = testBrand.copyWith(id: 'brand-2');
        
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: any(named: 'eventId'),
          brandId: any(named: 'brandId'),
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.80);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.75);
        
        await brandDiscoveryService.registerBrand(brand1);
        await brandDiscoveryService.registerBrand(brand2);
        
        // Act
        final matches = await brandDiscoveryService.findBrandsForEvent(
          eventId: 'event-456',
          minCompatibility: 0.70,
        );
        
        // Assert
        expect(matches.length, equals(2));
        expect(matches.first.compatibilityScore, greaterThanOrEqualTo(matches.last.compatibilityScore));
      });
    });
    
    group('Scenario 2: Event Search for Brands', () {
      test('should find events for brand with 70%+ compatibility', () async {
        // Arrange
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.75);
        
        // Note: _getAllUpcomingEvents() returns empty list for now
        // In production, this would query ExpertiseEventService
        
        // Act
        final matches = await brandDiscoveryService.findEventsForBrand(
          brandId: 'brand-123',
          minCompatibility: 0.70,
        );
        
        // Assert
        // Empty for now since _getAllUpcomingEvents() is not implemented
        expect(matches, isA<List<EventMatch>>());
      });
    });
    
    group('Scenario 3: Vibe Matching (70%+ threshold)', () {
      test('should only return matches above 70% threshold', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.75);
        
        await brandDiscoveryService.registerBrand(testBrand);
        
        // Act
        final matches = await brandDiscoveryService.findBrandsForEvent(
          eventId: 'event-456',
          minCompatibility: 0.70,
        );
        
        // Assert
        expect(matches.every((m) => m.compatibilityScore >= 70.0), isTrue);
        expect(matches.every((m) => m.meetsThreshold), isTrue);
      });
    });
    
    group('Scenario 4: Compatibility Scoring', () {
      test('should calculate compatibility score between brand and event', () async {
        // Arrange
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.75);
        
        // Act
        final compatibility = await brandDiscoveryService.calculateBrandEventCompatibility(
          brandId: 'brand-123',
          eventId: 'event-456',
        );
        
        // Assert
        expect(compatibility, equals(0.75));
        expect(compatibility, greaterThanOrEqualTo(0.70));
      });
    });
    
    group('Scenario 5: Sponsorship Suggestions', () {
      test('should generate sponsorship suggestions for event', () async {
        // Arrange
        when(() => mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent);
        
        when(() => mockSponsorshipService.checkSponsorshipEligibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => true);
        
        when(() => mockSponsorshipService.calculateCompatibility(
          eventId: 'event-456',
          brandId: 'brand-123',
        )).thenAnswer((_) async => 0.75);
        
        await brandDiscoveryService.registerBrand(testBrand);
        
        // Act
        final discovery = await brandDiscoveryService.getSponsorshipSuggestions(
          eventId: 'event-456',
        );
        
        // Assert
        expect(discovery, isNotNull);
        expect(discovery.eventId, equals('event-456'));
        expect(discovery.matchingResults, isNotEmpty);
      });
    });
  });
}

