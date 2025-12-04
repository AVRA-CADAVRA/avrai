import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'partnership_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService, BusinessService])
void main() {
  group('PartnershipService Tests', () {
    late PartnershipService service;
    late MockExpertiseEventService mockEventService;
    late MockBusinessService mockBusinessService;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockBusinessService = MockBusinessService();
      
      service = PartnershipService(
        eventService: mockEventService,
        businessService: mockBusinessService,
      );

      // Create test user with Local-level expertise (can host events)
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      // Add expertise to make user eligible (expertiseMap uses string values)
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
      );

      // Create test business
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        isVerified: true,
        isActive: true,
        categories: ['Coffee'],
        location: 'San Francisco',
      );

      // Create test event
      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('createPartnership', () {
      test('should create partnership with valid inputs', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75, // 75% compatibility (above 70% threshold)
        );

        // Assert
        expect(partnership, isA<EventPartnership>());
        expect(partnership.eventId, equals('event-123'));
        expect(partnership.userId, equals('user-123'));
        expect(partnership.businessId, equals('business-123'));
        expect(partnership.status, equals(PartnershipStatus.proposed));
        expect(partnership.vibeCompatibilityScore, equals(0.75));
        expect(partnership.userApproved, isFalse);
        expect(partnership.businessApproved, isFalse);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.createPartnership(
            eventId: 'event-123',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });

      test('should throw exception if business not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.createPartnership(
            eventId: 'event-123',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Business not found'),
          )),
        );
      });

      test('should throw exception if partnership not eligible', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => service.createPartnership(
            eventId: 'event-123',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership not eligible'),
          )),
        );
      });

      test('should throw exception if compatibility below 70% threshold', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => service.createPartnership(
            eventId: 'event-123',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.65, // Below 70% threshold
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Compatibility below 70% threshold'),
          )),
        );
      });

      test('should create partnership with agreement terms', () async {
        // Arrange
        final agreement = PartnershipAgreement(
          revenueSplit: [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 50.0,
              name: 'User',
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 50.0,
              name: 'Business',
            ),
          ],
          agreedAt: DateTime.now(),
        );

        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        // Act
        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          agreement: agreement,
          vibeCompatibilityScore: 0.80,
        );

        // Assert
        expect(partnership.agreement, isNotNull);
        expect(partnership.agreement?.revenueSplit, hasLength(2));
      });
    });

    group('getPartnershipsForEvent', () {
      test('should return partnerships for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        // Create a partnership first
        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final partnerships = await service.getPartnershipsForEvent('event-123');

        // Assert
        expect(partnerships, isNotEmpty);
        expect(partnerships.first.id, equals(partnership.id));
        expect(partnerships.first.eventId, equals('event-123'));
      });

      test('should return empty list if no partnerships exist', () async {
        // Act
        final partnerships = await service.getPartnershipsForEvent('event-none');

        // Assert
        expect(partnerships, isEmpty);
      });
    });

    group('getPartnershipById', () {
      test('should return partnership by ID', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final created = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final partnership = await service.getPartnershipById(created.id);

        // Assert
        expect(partnership, isNotNull);
        expect(partnership?.id, equals(created.id));
      });

      test('should return null if partnership not found', () async {
        // Act
        final partnership = await service.getPartnershipById('nonexistent-id');

        // Assert
        expect(partnership, isNull);
      });
    });

    group('updatePartnershipStatus', () {
      test('should update partnership status', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final updated = await service.updatePartnershipStatus(
          partnershipId: partnership.id,
          status: PartnershipStatus.negotiating,
        );

        // Assert
        expect(updated.status, equals(PartnershipStatus.negotiating));
        expect(updated.updatedAt.isAfter(partnership.updatedAt), isTrue);
      });

      test('should throw exception if partnership not found', () async {
        // Act & Assert
        expect(
          () => service.updatePartnershipStatus(
            partnershipId: 'nonexistent-id',
            status: PartnershipStatus.negotiating,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Partnership not found'),
          )),
        );
      });

      test('should throw exception if status transition is invalid', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act & Assert - Cannot go from proposed directly to completed
        expect(
          () => service.updatePartnershipStatus(
            partnershipId: partnership.id,
            status: PartnershipStatus.completed,
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid status transition'),
          )),
        );
      });
    });

    group('approvePartnership', () {
      test('should approve partnership by user', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final approved = await service.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: 'user-123',
        );

        // Assert
        expect(approved.userApproved, isTrue);
        expect(approved.businessApproved, isFalse);
      });

      test('should approve partnership by business', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act
        final approved = await service.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: 'business-123',
        );

        // Assert
        expect(approved.userApproved, isFalse);
        expect(approved.businessApproved, isTrue);
      });

      test('should lock partnership when both parties approve', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Approve by user
        await service.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: 'user-123',
        );

        // Act - Approve by business (both parties now approved)
        final locked = await service.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: 'business-123',
        );

        // Assert
        expect(locked.userApproved, isTrue);
        expect(locked.businessApproved, isTrue);
        expect(locked.status, equals(PartnershipStatus.locked));
      });

      test('should throw exception if invalid approver', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Act & Assert
        expect(
          () => service.approvePartnership(
            partnershipId: partnership.id,
            approvedBy: 'invalid-user',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid approver'),
          )),
        );
      });
    });

    group('checkPartnershipEligibility', () {
      test('should return true for eligible partnership', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        // Act
        final isEligible = await service.checkPartnershipEligibility(
          userId: 'user-123',
          businessId: 'business-123',
          eventId: 'event-123',
        );

        // Assert
        expect(isEligible, isTrue);
      });

      test('should return false if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act
        final isEligible = await service.checkPartnershipEligibility(
          userId: 'user-123',
          businessId: 'business-123',
          eventId: 'event-123',
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
        final isEligible = await service.checkPartnershipEligibility(
          userId: 'user-123',
          businessId: 'business-123',
          eventId: 'event-123',
        );

        // Assert
        expect(isEligible, isFalse);
      });

      test('should return false if business not verified', () async {
        // Arrange
        final unverifiedBusiness = testBusiness.copyWith(isVerified: false);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => unverifiedBusiness);

        // Act
        final isEligible = await service.checkPartnershipEligibility(
          userId: 'user-123',
          businessId: 'business-123',
          eventId: 'event-123',
        );

        // Assert
        expect(isEligible, isFalse);
      });
    });

    group('calculateVibeCompatibility', () {
      test('should return compatibility score', () async {
        // Act
        final compatibility = await service.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });
  });
}

