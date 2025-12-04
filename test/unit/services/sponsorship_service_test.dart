import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/brand_account.dart';
import '../../fixtures/model_factories.dart';

import 'sponsorship_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService, PartnershipService, BusinessService])
void main() {
  group('SponsorshipService Tests', () {
    late SponsorshipService service;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    late MockBusinessService mockBusinessService;
    late ExpertiseEvent testEvent;
    late BrandAccount testBrand;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();
      mockBusinessService = MockBusinessService();

      service = SponsorshipService(
        eventService: mockEventService,
        partnershipService: mockPartnershipService,
        businessService: mockBusinessService,
      );

      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Brand Event',
        description: 'An event with brand sponsorship',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Test Brand',
        brandType: 'Coffee Roaster',
        contactEmail: 'test@brand.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('createSponsorship', () {
      test('should create financial sponsorship with valid inputs', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Register brand in service
        await service.registerBrand(testBrand);

        // Act
        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75, // 75% compatibility (above 70% threshold)
        );

        // Assert
        expect(sponsorship, isA<Sponsorship>());
        expect(sponsorship.eventId, equals('event-123'));
        expect(sponsorship.brandId, equals('brand-123'));
        expect(sponsorship.type, equals(SponsorshipType.financial));
        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.status, equals(SponsorshipStatus.proposed));
      });

      test('should create product sponsorship', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 300.00,
          vibeCompatibilityScore: 0.80,
        );

        // Assert
        expect(sponsorship.type, equals(SponsorshipType.product));
        expect(sponsorship.productValue, equals(300.00));
      });

      test('should create hybrid sponsorship', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.hybrid,
          contributionAmount: 500.00,
          productValue: 300.00,
          vibeCompatibilityScore: 0.75,
        );

        // Assert
        expect(sponsorship.type, equals(SponsorshipType.hybrid));
        expect(sponsorship.contributionAmount, equals(500.00));
        expect(sponsorship.productValue, equals(300.00));
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });

      test('should throw exception if brand not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'nonexistent-brand',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Brand account not found'),
          )),
        );
      });

      test('should throw exception if brand not verified', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Create unverified brand
        final unverifiedBrand = BrandAccount(
          id: 'brand-unverified',
          name: 'Unverified Brand',
          brandType: 'Coffee Roaster',
          contactEmail: 'unverified@brand.com',
          verificationStatus: BrandVerificationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await service.registerBrand(unverifiedBrand);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-unverified',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Brand account not verified'),
          )),
        );
      });

      test('should throw exception if compatibility below 70% threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            contributionAmount: 500.00,
            vibeCompatibilityScore: 0.65, // Below 70% threshold
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Compatibility below 70% threshold'),
          )),
        );
      });

      test('should throw exception if financial sponsorship missing contributionAmount', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.financial,
            vibeCompatibilityScore: 0.75,
            // Missing contributionAmount
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Financial sponsorship requires contributionAmount'),
          )),
        );
      });

      test('should throw exception if product sponsorship missing productValue', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act & Assert
        expect(
          () => service.createSponsorship(
            eventId: 'event-123',
            brandId: 'brand-123',
            type: SponsorshipType.product,
            vibeCompatibilityScore: 0.75,
            // Missing productValue
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Product sponsorship requires productValue'),
          )),
        );
      });
    });

    group('getSponsorshipsForEvent', () {
      test('should return sponsorships for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Create sponsorship first
        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final sponsorships = await service.getSponsorshipsForEvent('event-123');

        // Assert
        expect(sponsorships, isNotEmpty);
        expect(sponsorships.first.id, equals(sponsorship.id));
        expect(sponsorships.first.eventId, equals('event-123'));
      });

      test('should return empty list if no sponsorships exist', () async {
        // Act
        final sponsorships = await service.getSponsorshipsForEvent('event-none');

        // Assert
        expect(sponsorships, isEmpty);
      });
    });

    group('getSponsorshipById', () {
      test('should return sponsorship by ID', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        final created = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final sponsorship = await service.getSponsorshipById(created.id);

        // Assert
        expect(sponsorship, isNotNull);
        expect(sponsorship?.id, equals(created.id));
      });

      test('should return null if sponsorship not found', () async {
        // Act
        final sponsorship = await service.getSponsorshipById('nonexistent-id');

        // Assert
        expect(sponsorship, isNull);
      });
    });

    group('updateSponsorshipStatus', () {
      test('should update sponsorship status', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final updated = await service.updateSponsorshipStatus(
          sponsorshipId: sponsorship.id,
          status: SponsorshipStatus.negotiating,
        );

        // Assert
        expect(updated.status, equals(SponsorshipStatus.negotiating));
        expect(updated.updatedAt.isAfter(sponsorship.updatedAt), isTrue);
      });

      test('should throw exception if sponsorship not found', () async {
        // Act & Assert
        expect(
          () => service.updateSponsorshipStatus(
            sponsorshipId: 'nonexistent-id',
            status: SponsorshipStatus.negotiating,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sponsorship not found'),
          )),
        );
      });

      test('should throw exception if status transition is invalid', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        final sponsorship = await service.createSponsorship(
          eventId: 'event-123',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          vibeCompatibilityScore: 0.75,
        );

        // Act & Assert - Cannot go from proposed directly to completed
        expect(
          () => service.updateSponsorshipStatus(
            sponsorshipId: sponsorship.id,
            status: SponsorshipStatus.completed,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid status transition'),
          )),
        );
      });
    });

    group('checkSponsorshipEligibility', () {
      test('should return true for eligible sponsorship', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final isEligible = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );

        // Assert
        expect(isEligible, isTrue);
      });

      test('should return false if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act
        final isEligible = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );

        // Assert
        expect(isEligible, isFalse);
      });

      test('should return false if event has already started', () async {
        // Arrange
        final pastEvent = testEvent.copyWith(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(hours: 23)),
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => pastEvent);

        // Act
        final isEligible = await service.checkSponsorshipEligibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );

        // Assert
        expect(isEligible, isFalse);
      });
    });

    group('calculateCompatibility', () {
      test('should return compatibility score', () async {
        // Act
        final compatibility = await service.calculateCompatibility(
          eventId: 'event-123',
          brandId: 'brand-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });
  });
}

