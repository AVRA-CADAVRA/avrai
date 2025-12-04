import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/partnership_matching_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/business_account.dart';
import '../../fixtures/model_factories.dart';

import 'partnership_matching_service_test.mocks.dart';

@GenerateMocks([PartnershipService, BusinessService, ExpertiseEventService])
void main() {
  group('PartnershipMatchingService Tests', () {
    late PartnershipMatchingService service;
    late MockPartnershipService mockPartnershipService;
    late MockBusinessService mockBusinessService;
    late MockExpertiseEventService mockEventService;
    late ExpertiseEvent testEvent;
    late BusinessAccount testBusiness1;
    late BusinessAccount testBusiness2;

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      mockBusinessService = MockBusinessService();
      mockEventService = MockExpertiseEventService();

      service = PartnershipMatchingService(
        partnershipService: mockPartnershipService,
        businessService: mockBusinessService,
        eventService: mockEventService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Meetup',
        description: 'A coffee meetup event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: 'San Francisco',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBusiness1 = BusinessAccount(
        id: 'business-1',
        name: 'Coffee Shop 1',
        email: 'shop1@coffee.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        isVerified: true,
        isActive: true,
        categories: ['Coffee'],
        location: 'San Francisco',
      );

      testBusiness2 = BusinessAccount(
        id: 'business-2',
        name: 'Coffee Shop 2',
        email: 'shop2@coffee.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        isVerified: true,
        isActive: true,
        categories: ['Coffee'],
        location: 'San Francisco',
      );
    });

    group('findMatchingPartners', () {
      test('should return matching partners with 70%+ compatibility', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
          verifiedOnly: true,
          maxResults: 50,
        )).thenAnswer((_) async => [testBusiness1, testBusiness2]);
        when(mockBusinessService.checkBusinessEligibility('business-1'))
            .thenAnswer((_) async => true);
        when(mockBusinessService.checkBusinessEligibility('business-2'))
            .thenAnswer((_) async => true);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        )).thenAnswer((_) async => 0.75); // 75% compatibility
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-2',
        )).thenAnswer((_) async => 0.80); // 80% compatibility

        // Act
        final suggestions = await service.findMatchingPartners(
          userId: 'user-123',
          eventId: 'event-123',
          minCompatibility: 0.70,
        );

        // Assert
        expect(suggestions, isNotEmpty);
        expect(suggestions.length, equals(2));
        expect(suggestions[0].compatibility, greaterThanOrEqualTo(0.70));
        expect(suggestions[1].compatibility, greaterThanOrEqualTo(0.70));
        // Should be sorted by compatibility (highest first)
        expect(suggestions[0].compatibility, greaterThanOrEqualTo(suggestions[1].compatibility));
      });

      test('should filter out partners below 70% compatibility threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
          verifiedOnly: true,
          maxResults: 50,
        )).thenAnswer((_) async => [testBusiness1, testBusiness2]);
        when(mockBusinessService.checkBusinessEligibility('business-1'))
            .thenAnswer((_) async => true);
        when(mockBusinessService.checkBusinessEligibility('business-2'))
            .thenAnswer((_) async => true);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        )).thenAnswer((_) async => 0.65); // 65% compatibility (below threshold)
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-2',
        )).thenAnswer((_) async => 0.75); // 75% compatibility (above threshold)

        // Act
        final suggestions = await service.findMatchingPartners(
          userId: 'user-123',
          eventId: 'event-123',
          minCompatibility: 0.70,
        );

        // Assert
        expect(suggestions.length, equals(1));
        expect(suggestions[0].businessId, equals('business-2'));
        expect(suggestions[0].compatibility, greaterThanOrEqualTo(0.70));
      });

      test('should return empty list if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act
        final suggestions = await service.findMatchingPartners(
          userId: 'user-123',
          eventId: 'event-123',
        );

        // Assert
        expect(suggestions, isEmpty);
      });

      test('should filter out ineligible businesses', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
          verifiedOnly: true,
          maxResults: 50,
        )).thenAnswer((_) async => [testBusiness1, testBusiness2]);
        when(mockBusinessService.checkBusinessEligibility('business-1'))
            .thenAnswer((_) async => false); // Not eligible
        when(mockBusinessService.checkBusinessEligibility('business-2'))
            .thenAnswer((_) async => true);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-2',
        )).thenAnswer((_) async => 0.75);

        // Act
        final suggestions = await service.findMatchingPartners(
          userId: 'user-123',
          eventId: 'event-123',
        );

        // Assert
        expect(suggestions.length, equals(1));
        expect(suggestions[0].businessId, equals('business-2'));
      });

      test('should respect custom minCompatibility threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
          verifiedOnly: true,
          maxResults: 50,
        )).thenAnswer((_) async => [testBusiness1, testBusiness2]);
        when(mockBusinessService.checkBusinessEligibility('business-1'))
            .thenAnswer((_) async => true);
        when(mockBusinessService.checkBusinessEligibility('business-2'))
            .thenAnswer((_) async => true);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        )).thenAnswer((_) async => 0.75);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-2',
        )).thenAnswer((_) async => 0.85);

        // Act - Use higher threshold (80%)
        final suggestions = await service.findMatchingPartners(
          userId: 'user-123',
          eventId: 'event-123',
          minCompatibility: 0.80,
        );

        // Assert
        expect(suggestions.length, equals(1));
        expect(suggestions[0].businessId, equals('business-2'));
        expect(suggestions[0].compatibility, greaterThanOrEqualTo(0.80));
      });
    });

    group('calculateCompatibility', () {
      test('should calculate compatibility score', () async {
        // Arrange
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        )).thenAnswer((_) async => 0.75);

        // Act
        final compatibility = await service.calculateCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, equals(0.75));
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should return score between 0.0 and 1.0', () async {
        // Arrange
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        )).thenAnswer((_) async => 0.90);

        // Act
        final compatibility = await service.calculateCompatibility(
          userId: 'user-123',
          businessId: 'business-1',
        );

        // Assert
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });
  });
}

