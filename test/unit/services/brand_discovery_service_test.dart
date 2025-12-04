import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/brand_discovery_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/brand_account.dart';
import 'package:spots/core/models/brand_discovery.dart';
import '../../fixtures/model_factories.dart';

import 'brand_discovery_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService, SponsorshipService])
void main() {
  group('BrandDiscoveryService Tests', () {
    late BrandDiscoveryService service;
    late MockExpertiseEventService mockEventService;
    late MockSponsorshipService mockSponsorshipService;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand1;
    late BrandAccount testBrand2;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockSponsorshipService = MockSponsorshipService();

      service = BrandDiscoveryService(
        eventService: mockEventService,
        sponsorshipService: mockSponsorshipService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Event',
        description: 'A coffee event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand1 = BrandAccount(
        id: 'brand-1',
        name: 'Coffee Brand 1',
        brandType: 'Coffee Roaster',
        contactEmail: 'brand1@coffee.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand2 = BrandAccount(
        id: 'brand-2',
        name: 'Coffee Brand 2',
        brandType: 'Coffee Roaster',
        contactEmail: 'brand2@coffee.com',
        verificationStatus: BrandVerificationStatus.verified,
        categories: ['Coffee'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('findBrandsForEvent', () {
      test('should return matching brands with 70%+ compatibility', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75); // 75% compatibility
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.80); // 80% compatibility

        // Register brands
        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);

        // Act
        final matches = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.70,
        );

        // Assert
        expect(matches, isNotEmpty);
        expect(matches.length, greaterThanOrEqualTo(2));
        expect(matches[0].compatibilityScore, greaterThanOrEqualTo(70.0));
        expect(matches[1].compatibilityScore, greaterThanOrEqualTo(70.0));
        // Should be sorted by compatibility (highest first)
        expect(matches[0].compatibilityScore, greaterThanOrEqualTo(matches[1].compatibilityScore));
      });

      test('should filter out brands below 70% compatibility threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.65); // 65% compatibility (below threshold)
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.75); // 75% compatibility (above threshold)

        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);

        // Act
        final matches = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.70,
        );

        // Assert
        expect(matches.length, equals(1));
        expect(matches[0].brandId, equals('brand-2'));
        expect(matches[0].compatibilityScore, greaterThanOrEqualTo(70.0));
      });

      test('should return empty list if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act
        final matches = await service.findBrandsForEvent(
          eventId: 'event-123',
        );

        // Assert
        expect(matches, isEmpty);
      });

      test('should respect custom minCompatibility threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.85);

        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);

        // Act - Use higher threshold (80%)
        final matches = await service.findBrandsForEvent(
          eventId: 'event-123',
          minCompatibility: 0.80,
        );

        // Assert
        expect(matches.length, equals(1));
        expect(matches[0].brandId, equals('brand-2'));
        expect(matches[0].compatibilityScore, greaterThanOrEqualTo(80.0));
      });
    });

    group('findEventsForBrand', () {
      test('should return matching events for brand', () async {
        // Arrange
        when(mockEventService.searchEvents(
          category: 'Coffee',
          location: anyNamed('location'),
        )).thenAnswer((_) async => [testEvent]);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);

        await service.registerBrand(testBrand1);

        // Act
        final matches = await service.findEventsForBrand(
          brandId: 'brand-1',
          minCompatibility: 0.70,
        );

        // Assert
        expect(matches, isNotEmpty);
        expect(matches[0].compatibilityScore, greaterThanOrEqualTo(70.0));
      });
    });

    group('calculateBrandEventCompatibility', () {
      test('should calculate compatibility score', () async {
        // Arrange
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);

        // Act
        final compatibility = await service.calculateBrandEventCompatibility(
          brandId: 'brand-1',
          eventId: 'event-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, equals(0.75));
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('getSponsorshipSuggestions', () {
      test('should return sponsorship suggestions', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-2',
        )).thenAnswer((_) async => 0.80);

        await service.registerBrand(testBrand1);
        await service.registerBrand(testBrand2);

        // Act
        final discovery = await service.getSponsorshipSuggestions(
          eventId: 'event-123',
        );

        // Assert
        expect(discovery, isA<BrandDiscovery>());
        expect(discovery.eventId, equals('event-123'));
        expect(discovery.matchingResults, isNotEmpty);
      });

      test('should filter by search criteria', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockSponsorshipService.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-1',
        )).thenAnswer((_) async => 0.75);

        await service.registerBrand(testBrand1);

        // Act
        final discovery = await service.getSponsorshipSuggestions(
          eventId: 'event-123',
          searchCriteria: {
            'category': 'Coffee',
            'minContribution': 500.0,
          },
        );

        // Assert
        expect(discovery.searchCriteria, isNotNull);
        expect(discovery.searchCriteria['category'], equals('Coffee'));
      });
    });
  });
}

