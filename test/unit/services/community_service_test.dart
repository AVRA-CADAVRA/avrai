import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for CommunityService
/// Tests auto-create community from event, member management, event management, growth tracking
/// 
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities form organically from successful events
/// - People find their communities through events
void main() {
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
        attendeeIds: ['user-1', 'user-2', 'user-3', 'user-4', 'user-5', 'user-6'],
        attendeeCount: 6,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Auto-Create Community From Event', () {
      test('should create community from successful CommunityEvent', () async {
        final community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );

        expect(community, isNotNull);
        expect(community.name, contains('Coffee Community'));
        expect(community.name, contains('Coffee Meetup'));
        expect(community.category, equals('Coffee'));
        expect(community.originatingEventId, equals(successfulEvent.id));
        expect(community.originatingEventType, equals(OriginatingEventType.communityEvent));
        expect(community.founderId, equals(host.id));
        expect(community.memberIds, contains(host.id));
        expect(community.memberIds.length, equals(6)); // 5 attendees + 1 host
        expect(community.memberCount, equals(6));
        expect(community.eventIds, contains(successfulEvent.id));
        expect(community.eventCount, equals(1));
        expect(community.originalLocality, equals('Mission District'));
        expect(community.currentLocalities, contains('Mission District'));
        expect(community.engagementScore, equals(0.75));
        expect(community.diversityScore, equals(0.0)); // From diversityMetrics
      });

      test('should create community from successful ExpertiseEvent', () async {
        final community = await service.createCommunityFromEvent(
          event: expertiseEvent,
        );

        expect(community, isNotNull);
        expect(community.originatingEventType, equals(OriginatingEventType.expertiseEvent));
        expect(community.memberIds.length, equals(7)); // 6 attendees + 1 host
        expect(community.memberCount, equals(7));
      });

      test('should throw error if event has too few attendees', () async {
        expect(
          () => service.createCommunityFromEvent(
            event: unsuccessfulEvent,
            minAttendees: 5,
          ),
          throwsException,
        );
      });

      test('should throw error if CommunityEvent has too few repeat attendees', () async {
        final eventWithLowRepeats = successfulEvent.copyWith(
          repeatAttendeesCount: 1, // Below default threshold of 2
        );

        expect(
          () => service.createCommunityFromEvent(
            event: eventWithLowRepeats,
            minRepeatAttendees: 2,
          ),
          throwsException,
        );
      });

      test('should throw error if CommunityEvent has low engagement score', () async {
        final eventWithLowEngagement = successfulEvent.copyWith(
          engagementScore: 0.5, // Below default threshold of 0.6
        );

        expect(
          () => service.createCommunityFromEvent(
            event: eventWithLowEngagement,
            minEngagementScore: 0.6,
          ),
          throwsException,
        );
      });

      test('should extract locality from event location correctly', () async {
        final eventWithLocation = successfulEvent.copyWith(
          location: 'Castro, San Francisco, CA, USA',
        );

        final community = await service.createCommunityFromEvent(
          event: eventWithLocation,
        );

        expect(community.originalLocality, equals('Castro'));
        expect(community.currentLocalities, contains('Castro'));
      });

      test('should use "Unknown" locality if event has no location', () async {
        final eventWithoutLocation = successfulEvent.copyWith(
          location: null,
        );

        final community = await service.createCommunityFromEvent(
          event: eventWithoutLocation,
        );

        expect(community.originalLocality, equals('Unknown'));
        expect(community.currentLocalities, contains('Unknown'));
      });

      test('should include host and all attendees as initial members', () async {
        final community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );

        expect(community.memberIds, contains(host.id));
        expect(community.memberIds, containsAll(successfulEvent.attendeeIds));
        expect(community.memberCount, equals(successfulEvent.attendeeCount + 1));
      });
    });

    group('Member Management', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test('should add member to community', () async {
        const newMemberId = 'new-member-1';

        await service.addMember(community, newMemberId);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.memberIds, contains(newMemberId));
        expect(updated.memberCount, equals(community.memberCount + 1));
      });

      test('should not add duplicate member', () async {
        const existingMemberId = 'user-1';

        await service.addMember(community, existingMemberId);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        // Member count should not increase
        expect(updated!.memberCount, equals(community.memberCount));
      });

      test('should remove member from community', () async {
        const memberToRemove = 'user-1';

        await service.removeMember(community, memberToRemove);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.memberIds, isNot(contains(memberToRemove)));
        expect(updated.memberCount, equals(community.memberCount - 1));
      });

      test('should not remove non-member', () async {
        const nonMemberId = 'non-member-1';

        await service.removeMember(community, nonMemberId);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        // Member count should not change
        expect(updated!.memberCount, equals(community.memberCount));
      });

      test('should throw error when trying to remove founder', () async {
        expect(
          () => service.removeMember(community, community.founderId),
          throwsException,
        );
      });

      test('should get all members', () {
        final members = service.getMembers(community);

        expect(members, equals(community.memberIds));
        expect(members.length, equals(community.memberCount));
      });

      test('should check if user is member', () {
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

      test('should add event to community', () async {
        const newEventId = 'event-new-1';

        await service.addEvent(community, newEventId);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.eventIds, contains(newEventId));
        expect(updated.eventCount, equals(community.eventCount + 1));
      });

      test('should not add duplicate event', () async {
        await service.addEvent(community, successfulEvent.id);

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        // Event count should not increase
        expect(updated!.eventCount, equals(community.eventCount));
      });

      test('should get all events', () {
        final events = service.getEvents(community);

        expect(events, equals(community.eventIds));
        expect(events.length, equals(community.eventCount));
      });

      test('should get upcoming events', () {
        final upcomingEvents = service.getUpcomingEvents(community);

        // Note: Current implementation returns all events
        // In production, would filter by event dates
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

      test('should update member growth rate', () async {
        await service.updateGrowthMetrics(
          community,
          memberGrowthRate: 0.25,
        );

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.memberGrowthRate, equals(0.25));
      });

      test('should update event growth rate', () async {
        await service.updateGrowthMetrics(
          community,
          eventGrowthRate: 0.15,
        );

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.eventGrowthRate, equals(0.15));
      });

      test('should update both growth rates', () async {
        await service.updateGrowthMetrics(
          community,
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
        );

        final updated = await service.getCommunityById(community.id);
        expect(updated, isNotNull);
        expect(updated!.memberGrowthRate, equals(0.25));
        expect(updated.eventGrowthRate, equals(0.15));
      });

      test('should calculate engagement score', () {
        final communityWithMetrics = community.copyWith(
          memberCount: 25,
          eventCount: 5,
          memberGrowthRate: 0.2,
        );

        final score = service.calculateEngagementScore(communityWithMetrics);

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        // Score should be positive for active community
        expect(score, greaterThan(0.0));
      });

      test('should calculate diversity score', () {
        final communityWithDiversity = community.copyWith(
          diversityScore: 0.6,
          currentLocalities: [
            'Mission District',
            'Castro',
            'Haight-Ashbury',
          ],
        );

        final score = service.calculateDiversityScore(communityWithDiversity);

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        // Score should reflect diversity
        expect(score, greaterThan(0.0));
      });
    });

    group('Community Management', () {
      late Community community;

      setUp(() async {
        community = await service.createCommunityFromEvent(
          event: successfulEvent,
        );
      });

      test('should get community by ID', () async {
        final retrieved = await service.getCommunityById(community.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(community.id));
        expect(retrieved.name, equals(community.name));
      });

      test('should return null for non-existent community', () async {
        final retrieved = await service.getCommunityById('non-existent-id');

        expect(retrieved, isNull);
      });

      test('should get communities by founder', () async {
        final communities = await service.getCommunitiesByFounder(host.id);

        expect(communities, isNotEmpty);
        expect(communities.any((c) => c.id == community.id), isTrue);
        expect(communities.every((c) => c.founderId == host.id), isTrue);
      });

      test('should get communities by category', () async {
        final communities = await service.getCommunitiesByCategory('Coffee');

        expect(communities, isNotEmpty);
        expect(communities.any((c) => c.id == community.id), isTrue);
        expect(communities.every((c) => c.category == 'Coffee'), isTrue);
      });

      test('should limit results when getting communities by category', () async {
        final communities = await service.getCommunitiesByCategory(
          'Coffee',
          maxResults: 1,
        );

        expect(communities.length, lessThanOrEqualTo(1));
      });

      test('should update community details', () async {
        final updated = await service.updateCommunity(
          community: community,
          name: 'Updated Name',
          description: 'Updated Description',
          currentLocalities: ['Castro', 'Haight-Ashbury'],
        );

        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals('Updated Description'));
        expect(updated.currentLocalities, equals(['Castro', 'Haight-Ashbury']));
      });

      test('should preserve existing values when updating with null', () async {
        final updated = await service.updateCommunity(
          community: community,
          name: 'Updated Name',
        );

        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals(community.description));
        expect(updated.currentLocalities, equals(community.currentLocalities));
      });

      test('should delete empty community', () async {
        // Create empty community
        final emptyCommunity = await service.createCommunityFromEvent(
          event: successfulEvent,
        );

        // Remove all members except founder
        for (final memberId in emptyCommunity.memberIds) {
          if (memberId != emptyCommunity.founderId) {
            await service.removeMember(emptyCommunity, memberId);
          }
        }

        // Remove all events
        final updatedCommunity = await service.getCommunityById(emptyCommunity.id);
        if (updatedCommunity != null) {
          // Note: Service doesn't have removeEvent method, so we'll need to manually
          // create an empty community for this test
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
      });

      test('should throw error when trying to delete community with members', () async {
        expect(
          () => service.deleteCommunity(community),
          throwsException,
        );
      });

      test('should throw error when trying to delete community with events', () async {
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

