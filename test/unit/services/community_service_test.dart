import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Comprehensive tests for CommunityService
/// Tests auto-create community from event, member management, event management, growth tracking
///
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities form organically from successful events
/// - People find their communities through events
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('CommunityService Tests', () {
    late CommunityService service;
    late UnifiedUser host;
    late CommunityEvent successfulEvent;
    late CommunityEvent unsuccessfulEvent;
    late ExpertiseEvent expertiseEvent;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      service = CommunityService();
      testDate = TestHelpers.createTestDateTime();

      // Create host
      host = ModelFactories.createTestUser(
        id: 'host-1',
      );

      // Create successful community event (meets all criteria)
      successfulEvent = CommunityEvent(
        id: 'event-1',
        title: 'Coffee Meetup',
        description: 'Weekly coffee meetup',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        location: 'Mission District, San Francisco, CA, USA',
        attendeeIds: ['user-1', 'user-2', 'user-3', 'user-4', 'user-5'],
        attendeeCount: 5,
        repeatAttendeesCount: 3,
        engagementScore: 0.75,
      );

      // Create unsuccessful community event (doesn't meet criteria)
      unsuccessfulEvent = CommunityEvent(
        id: 'event-2',
        title: 'Small Meetup',
        description: 'Small gathering',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        location: 'Mission District, San Francisco, CA, USA',
        attendeeIds: ['user-1'],
        attendeeCount: 1, // Too few attendees
        repeatAttendeesCount: 0,
        engagementScore: 0.3,
      );

      // Create expertise event
      expertiseEvent = ExpertiseEvent(
        id: 'event-3',
        title: 'Expert Tour',
        description: 'Expert-led tour',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        host: host,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        location: 'Mission District, San Francisco, CA, USA',
        attendeeIds: [
          'user-1',
          'user-2',
          'user-3',
          'user-4',
          'user-5',
          'user-6'
        ],
        attendeeCount: 6,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Community creation tests focus on business logic validation, not property assignment

    group('Auto-Create Community From Event', () {
      test(
          'should create community from successful CommunityEvent and ExpertiseEvent with correct business logic, extract locality from event location or handle missing locations, include host and all attendees as initial members, or throw error for events that do not meet minimum criteria (attendees, repeat attendees, engagement)',
          () async {
        // Test business logic: community creation from events with validation
        final communityFromCommunityEvent =
            await service.createCommunityFromEvent(
          event: successfulEvent,
        );
        expect(communityFromCommunityEvent, isNotNull);
        expect(communityFromCommunityEvent.name, contains('Coffee Community'));
        expect(communityFromCommunityEvent.name, contains('Coffee Meetup'));
        expect(communityFromCommunityEvent.category, equals('Coffee'));
        expect(communityFromCommunityEvent.originatingEventId,
            equals(successfulEvent.id));
        expect(communityFromCommunityEvent.originatingEventType,
            equals(OriginatingEventType.communityEvent));
        expect(communityFromCommunityEvent.founderId, equals(host.id));
        expect(communityFromCommunityEvent.memberIds, contains(host.id));
        expect(communityFromCommunityEvent.memberIds.length, equals(6));
        expect(communityFromCommunityEvent.memberCount, equals(6));
        expect(
            communityFromCommunityEvent.eventIds, contains(successfulEvent.id));
        expect(communityFromCommunityEvent.eventCount, equals(1));
        expect(communityFromCommunityEvent.originalLocality,
            equals('Mission District'));
        expect(communityFromCommunityEvent.currentLocalities,
            contains('Mission District'));
        expect(communityFromCommunityEvent.engagementScore, equals(0.75));
        expect(communityFromCommunityEvent.diversityScore, equals(0.0));

        final communityFromExpertiseEvent =
            await service.createCommunityFromEvent(
          event: expertiseEvent,
        );
        expect(communityFromExpertiseEvent, isNotNull);
        expect(communityFromExpertiseEvent.originatingEventType,
            equals(OriginatingEventType.expertiseEvent));
        expect(communityFromExpertiseEvent.memberIds.length, equals(7));
        expect(communityFromExpertiseEvent.memberCount, equals(7));

        final eventWithLocation = successfulEvent.copyWith(
          location: 'Castro, San Francisco, CA, USA',
        );
        final communityWithLocation = await service.createCommunityFromEvent(
          event: eventWithLocation,
        );
        expect(communityWithLocation.originalLocality, equals('Castro'));
        expect(communityWithLocation.currentLocalities, contains('Castro'));

        final eventWithoutLocation = CommunityEvent(
          id: 'event-no-location',
          title: 'Event Without Location',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: host,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
          location: null,
          attendeeIds: ['user-1', 'user-2', 'user-3', 'user-4', 'user-5'],
          attendeeCount: 5,
          repeatAttendeesCount: 3,
          engagementScore: 0.75,
        );
        final communityWithoutLocation = await service.createCommunityFromEvent(
          event: eventWithoutLocation,
        );
        expect(communityWithoutLocation.originalLocality, equals('Unknown'));
        expect(communityWithoutLocation.currentLocalities, contains('Unknown'));

        final community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
        expect(community.memberIds, contains(host.id));
        expect(community.memberIds, containsAll(successfulEvent.attendeeIds));
        expect(
            community.memberCount, equals(successfulEvent.attendeeCount + 1));

        expect(
          () => service.createCommunityFromEvent(
            event: unsuccessfulEvent,
            minAttendees: 5,
          ),
          throwsException,
        );

        final eventWithLowRepeats = successfulEvent.copyWith(
          repeatAttendeesCount: 1,
        );
        expect(
          () => service.createCommunityFromEvent(
            event: eventWithLowRepeats,
            minRepeatAttendees: 2,
          ),
          throwsException,
        );

        final eventWithLowEngagement = successfulEvent.copyWith(
          engagementScore: 0.5,
        );
        expect(
          () => service.createCommunityFromEvent(
            event: eventWithLowEngagement,
            minEngagementScore: 0.6,
          ),
          throwsException,
        );
      });
    });

    group('Member Management', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test(
          'should add member to community, not add duplicate member, remove member from community, not remove non-member, throw error when trying to remove founder, get all members, and check if user is member',
          () async {
        // Test business logic: member management operations
        const newMemberId = 'new-member-1';
        await service.addMember(community, newMemberId);
        final updated1 = await service.getCommunityById(community.id);
        expect(updated1, isNotNull);
        expect(updated1!.memberIds, contains(newMemberId));
        expect(updated1.memberCount, equals(community.memberCount + 1));

        const existingMemberId = 'user-1';
        await service.addMember(community, existingMemberId);
        final updated2 = await service.getCommunityById(community.id);
        expect(updated2!.memberCount, equals(community.memberCount + 1));

        const memberToRemove = 'user-2';
        await service.removeMember(community, memberToRemove);
        final updated3 = await service.getCommunityById(community.id);
        expect(updated3, isNotNull);
        expect(updated3!.memberIds, isNot(contains(memberToRemove)));

        const nonMemberId = 'non-member-1';
        await service.removeMember(community, nonMemberId);
        final updated4 = await service.getCommunityById(community.id);
        expect(updated4!.memberCount, equals(updated3.memberCount));

        expect(
          () => service.removeMember(community, community.founderId),
          throwsException,
        );

        final members = service.getMembers(community);
        expect(members, equals(community.memberIds));
        expect(members.length, equals(community.memberCount));

        expect(service.isMember(community, 'user-1'), isTrue);
        expect(service.isMember(community, 'non-member-1'), isFalse);
      });
    });

    group('Event Management', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test(
          'should add event to community, not add duplicate event, get all events, and get upcoming events',
          () async {
        // Test business logic: event management operations
        const newEventId = 'event-new-1';
        await service.addEvent(community, newEventId);
        final updated1 = await service.getCommunityById(community.id);
        expect(updated1, isNotNull);
        expect(updated1!.eventIds, contains(newEventId));
        expect(updated1.eventCount, equals(community.eventCount + 1));

        await service.addEvent(community, successfulEvent.id);
        final updated2 = await service.getCommunityById(community.id);
        expect(updated2!.eventCount, equals(community.eventCount + 1));

        final events = service.getEvents(community);
        expect(events, equals(community.eventIds));
        expect(events.length, equals(community.eventCount));

        final upcomingEvents = service.getUpcomingEvents(community);
        expect(upcomingEvents, isA<List<String>>());
      });
    });

    group('Growth Tracking', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test(
          'should update member growth rate, event growth rate, both growth rates, calculate engagement score, and calculate diversity score',
          () async {
        // Test business logic: growth tracking and score calculations
        await service.updateGrowthMetrics(
          community,
          memberGrowthRate: 0.25,
        );
        final updated1 = await service.getCommunityById(community.id);
        expect(updated1!.memberGrowthRate, equals(0.25));

        await service.updateGrowthMetrics(
          community,
          eventGrowthRate: 0.15,
        );
        final updated2 = await service.getCommunityById(community.id);
        expect(updated2!.eventGrowthRate, equals(0.15));

        await service.updateGrowthMetrics(
          community,
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
        );
        final updated3 = await service.getCommunityById(community.id);
        expect(updated3!.memberGrowthRate, equals(0.25));
        expect(updated3.eventGrowthRate, equals(0.15));

        final communityWithMetrics = community.copyWith(
          memberCount: 25,
          eventCount: 5,
          memberGrowthRate: 0.2,
        );
        final engagementScore =
            service.calculateEngagementScore(communityWithMetrics);
        expect(engagementScore, greaterThanOrEqualTo(0.0));
        expect(engagementScore, lessThanOrEqualTo(1.0));
        expect(engagementScore, greaterThan(0.0));

        final communityWithDiversity = community.copyWith(
          diversityScore: 0.6,
          currentLocalities: [
            'Mission District',
            'Castro',
            'Haight-Ashbury',
          ],
        );
        final diversityScore =
            service.calculateDiversityScore(communityWithDiversity);
        expect(diversityScore, greaterThanOrEqualTo(0.0));
        expect(diversityScore, lessThanOrEqualTo(1.0));
        expect(diversityScore, greaterThan(0.0));
      });
    });

    group('Community Management', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test(
          'should get community by ID or return null for non-existent community, get communities by founder or category with maxResults limit, update community details preserving existing values when updating with null, and delete empty community or throw error when trying to delete community with members or events',
          () async {
        // Test business logic: community retrieval, filtering, updates, and deletion
        final retrieved1 = await service.getCommunityById(community.id);
        expect(retrieved1, isNotNull);
        expect(retrieved1!.id, equals(community.id));
        expect(retrieved1.name, equals(community.name));

        final retrieved2 = await service.getCommunityById('non-existent-id');
        expect(retrieved2, isNull);

        final communitiesByFounder =
            await service.getCommunitiesByFounder(host.id);
        expect(communitiesByFounder, isNotEmpty);
        expect(communitiesByFounder.any((c) => c.id == community.id), isTrue);
        expect(
            communitiesByFounder.every((c) => c.founderId == host.id), isTrue);

        final communitiesByCategory =
            await service.getCommunitiesByCategory('Coffee');
        expect(communitiesByCategory, isNotEmpty);
        expect(communitiesByCategory.any((c) => c.id == community.id), isTrue);
        expect(
            communitiesByCategory.every((c) => c.category == 'Coffee'), isTrue);

        final limitedCommunities = await service.getCommunitiesByCategory(
          'Coffee',
          maxResults: 1,
        );
        expect(limitedCommunities.length, lessThanOrEqualTo(1));

        final updated1 = await service.updateCommunity(
          community: community,
          name: 'Updated Name',
          description: 'Updated Description',
          currentLocalities: ['Castro', 'Haight-Ashbury'],
        );
        expect(updated1.name, equals('Updated Name'));
        expect(updated1.description, equals('Updated Description'));
        expect(
            updated1.currentLocalities, equals(['Castro', 'Haight-Ashbury']));

        final updated2 = await service.updateCommunity(
          community: community,
          name: 'Updated Name 2',
        );
        expect(updated2.name, equals('Updated Name 2'));
        expect(updated2.description, equals(community.description));
        expect(updated2.currentLocalities, equals(community.currentLocalities));

        final emptyCommunity = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
        for (final memberId in emptyCommunity.memberIds) {
          if (memberId != emptyCommunity.founderId) {
            await service.removeMember(emptyCommunity, memberId);
          }
        }
        final updatedCommunity =
            await service.getCommunityById(emptyCommunity.id);
        if (updatedCommunity != null) {
          final trulyEmpty = updatedCommunity.copyWith(
            memberIds: [],
            memberCount: 0,
            eventIds: [],
            eventCount: 0,
          );
          await service.deleteCommunity(trulyEmpty);
          final deleted = await service.getCommunityById(trulyEmpty.id);
          expect(deleted, isNull);
        }

        expect(
          () => service.deleteCommunity(community),
          throwsException,
        );

        final communityWithEvents = community.copyWith(
          memberIds: [],
          memberCount: 0,
        );
        expect(
          () => service.deleteCommunity(communityWithEvents),
          throwsException,
        );
      });
    });
  });
}
