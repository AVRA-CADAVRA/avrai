import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/partnership_profile_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/sponsorship_service.dart';
import 'package:spots/core/services/business_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'partnership_profile_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  PartnershipService,
  SponsorshipService,
  BusinessService,
  ExpertiseEventService,
])
void main() {
  group('PartnershipProfileService Tests', () {
    late PartnershipProfileService service;
    late MockPartnershipService mockPartnershipService;
    late MockSponsorshipService mockSponsorshipService;
    late MockBusinessService mockBusinessService;
    late MockExpertiseEventService mockEventService;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late ExpertiseEvent testEvent;

    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      mockSponsorshipService = MockSponsorshipService();
      mockBusinessService = MockBusinessService();
      mockEventService = MockExpertiseEventService();

      service = PartnershipProfileService(
        partnershipService: mockPartnershipService,
        sponsorshipService: mockSponsorshipService,
        businessService: mockBusinessService,
        eventService: mockEventService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );

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
        logoUrl: 'https://example.com/logo.png',
      );

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

    // Removed: Property assignment tests
    // Partnership profile tests focus on business logic (partnership retrieval, filtering, expertise boost), not property assignment

    group('getUserPartnerships', () {
      test(
          'should return empty list when user has no partnerships or return business partnerships',
          () async {
        // Test business logic: user partnership retrieval
        when(mockEventService.getEventsByHost(any)).thenAnswer((_) async => []);
        final partnerships1 = await service.getUserPartnerships('user-123');
        expect(partnerships1, isEmpty);

        final eventPartnership = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          vibeCompatibilityScore: 0.85,
        );
        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [eventPartnership]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final partnerships2 = await service.getUserPartnerships('user-123');
        expect(partnerships2.length, equals(1));
        expect(
            partnerships2.first.type, equals(ProfilePartnershipType.business));
        expect(partnerships2.first.partnerId, equals('business-123'));
        expect(partnerships2.first.partnerName, equals('Test Business'));
      });
    });

    group('getActivePartnerships', () {
      test('should return only active partnerships', () async {
        // Arrange
        final activePartnership = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final completedPartnership = EventPartnership(
          id: 'partnership-2',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          endDate: DateTime.now().subtract(const Duration(days: 10)),
        );

        final testEvent2 = testEvent.copyWith(id: 'event-456');

        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent, testEvent2]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [activePartnership]);
        when(mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => [completedPartnership]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent2);

        // Act
        final active = await service.getActivePartnerships('user-123');

        // Assert
        expect(active.length, equals(1));
        expect(active.first.status, equals(PartnershipStatus.active));
      });
    });

    group('getCompletedPartnerships', () {
      test('should return only completed partnerships', () async {
        // Arrange
        final activePartnership = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final completedPartnership = EventPartnership(
          id: 'partnership-2',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          endDate: DateTime.now().subtract(const Duration(days: 10)),
        );

        final testEvent2 = testEvent.copyWith(id: 'event-456');

        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent, testEvent2]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [activePartnership]);
        when(mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => [completedPartnership]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent2);

        // Act
        final completed = await service.getCompletedPartnerships('user-123');

        // Assert
        expect(completed.length, equals(1));
        expect(completed.first.status, equals(PartnershipStatus.completed));
      });
    });

    group('getPartnershipsByType', () {
      test('should filter partnerships by type', () async {
        // Arrange
        final businessPartnership = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [businessPartnership]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final business = await service.getPartnershipsByType(
          'user-123',
          ProfilePartnershipType.business,
        );

        // Assert
        expect(business.length, equals(1));
        expect(business.first.type, equals(ProfilePartnershipType.business));
      });
    });

    group('getPartnershipExpertiseBoost', () {
      test(
          'should return zero boost when user has no partnerships, calculate boost for active partnership, apply count multiplier for multiple partnerships, or cap boost at 0.50 (50%)',
          () async {
        // Test business logic: partnership expertise boost calculation
        when(mockEventService.getEventsByHost(any)).thenAnswer((_) async => []);
        final boost1 =
            await service.getPartnershipExpertiseBoost('user-123', 'Coffee');
        expect(boost1.totalBoost, equals(0.0));
        expect(boost1.partnershipCount, equals(0));

        final activePartnership = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          vibeCompatibilityScore: 0.85,
        );
        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [activePartnership]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final boost2 =
            await service.getPartnershipExpertiseBoost('user-123', 'Coffee');
        expect(boost2.totalBoost, greaterThan(0.0));
        expect(boost2.activeBoost, greaterThan(0.0));
        expect(boost2.partnershipCount, equals(1));

        final partnership1 = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final partnership2 = EventPartnership(
          id: 'partnership-2',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final partnership3 = EventPartnership(
          id: 'partnership-3',
          eventId: 'event-789',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final testEvent2 = testEvent.copyWith(id: 'event-456');
        final testEvent3 = testEvent.copyWith(id: 'event-789');
        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => [testEvent, testEvent2, testEvent3]);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [partnership1]);
        when(mockPartnershipService.getPartnershipsForEvent('event-456'))
            .thenAnswer((_) async => [partnership2]);
        when(mockPartnershipService.getPartnershipsForEvent('event-789'))
            .thenAnswer((_) async => [partnership3]);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent2);
        when(mockEventService.getEventById('event-789'))
            .thenAnswer((_) async => testEvent3);
        final boost3 =
            await service.getPartnershipExpertiseBoost('user-123', 'Coffee');
        expect(boost3.partnershipCount, equals(3));
        expect(boost3.countMultiplier, equals(1.2));

        final partnerships = List.generate(10, (index) {
          return EventPartnership(
            id: 'partnership-$index',
            eventId: 'event-$index',
            userId: 'user-123',
            businessId: 'business-123',
            status: PartnershipStatus.completed,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            endDate: DateTime.now().subtract(const Duration(days: 10)),
            vibeCompatibilityScore: 0.90,
          );
        });
        final events =
            partnerships.map((p) => testEvent.copyWith(id: p.eventId)).toList();
        when(mockEventService.getEventsByHost(any))
            .thenAnswer((_) async => events);
        for (final partnership in partnerships) {
          when(mockPartnershipService
                  .getPartnershipsForEvent(partnership.eventId))
              .thenAnswer((_) async => [partnership]);
        }
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        for (final event in events) {
          when(mockEventService.getEventById(event.id))
              .thenAnswer((_) async => event);
        }
        final boost4 =
            await service.getPartnershipExpertiseBoost('user-123', 'Coffee');
        expect(boost4.totalBoost, lessThanOrEqualTo(0.50));
      });
    });
  });
}
