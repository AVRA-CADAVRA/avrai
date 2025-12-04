import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Community Model
/// Tests community creation, event linking, member tracking, growth metrics
/// 
/// **Philosophy Alignment:**
/// - Events naturally create communities (people who attend together)
/// - Communities are doors to finding your people
/// - Communities track growth and engagement organically
void main() {
  group('Community Model Tests', () {
    late UnifiedUser founder;
    late CommunityEvent originatingEvent;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();

      // Create founder (event host)
      founder = ModelFactories.createTestUser(
        id: 'founder-1',
      );

      // Create originating event
      originatingEvent = CommunityEvent(
        id: 'event-1',
        title: 'Coffee Meetup',
        description: 'Weekly coffee meetup',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: founder,
        startTime: testDate.add(const Duration(days: 1)),
        endTime: testDate.add(const Duration(days: 1, hours: 2)),
        createdAt: testDate,
        updatedAt: testDate,
        attendeeIds: ['user-1', 'user-2', 'user-3'],
        attendeeCount: 3,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Model Creation', () {
      test('should create community with required fields', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          description: 'A community for coffee lovers',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community.id, equals('community-1'));
        expect(community.name, equals('Coffee Enthusiasts'));
        expect(community.description, equals('A community for coffee lovers'));
        expect(community.category, equals('Coffee'));
        expect(community.originatingEventId, equals(originatingEvent.id));
        expect(community.originatingEventType, equals(OriginatingEventType.communityEvent));
        expect(community.founderId, equals(founder.id));
        expect(community.originalLocality, equals('Mission District, San Francisco'));
      });

      test('should create community with default values', () {
        final community = Community(
          id: 'community-1',
          name: 'Test Community',
          category: 'Food',
          originatingEventId: 'event-1',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: 'founder-1',
          originalLocality: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community.memberIds, isEmpty);
        expect(community.memberCount, equals(0));
        expect(community.eventIds, isEmpty);
        expect(community.eventCount, equals(0));
        expect(community.memberGrowthRate, equals(0.0));
        expect(community.eventGrowthRate, equals(0.0));
        expect(community.engagementScore, equals(0.0));
        expect(community.diversityScore, equals(0.0));
        expect(community.activityLevel, equals(ActivityLevel.active));
        expect(community.currentLocalities, isEmpty);
      });

      test('should create community with initial members from event', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: originatingEvent.attendeeIds + [founder.id],
          memberCount: originatingEvent.attendeeCount + 1,
        );

        expect(community.memberIds, containsAll(['user-1', 'user-2', 'user-3', founder.id]));
        expect(community.memberCount, equals(4));
      });
    });

    group('Event Linking', () {
      test('should link to originating event', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community.originatingEventId, equals(originatingEvent.id));
        expect(community.originatingEventType, equals(OriginatingEventType.communityEvent));
      });

      test('should support both CommunityEvent and ExpertiseEvent as originating event', () {
        final communityFromCommunityEvent = Community(
          id: 'community-1',
          name: 'Community 1',
          category: 'Coffee',
          originatingEventId: 'event-1',
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final communityFromExpertiseEvent = Community(
          id: 'community-2',
          name: 'Community 2',
          category: 'Coffee',
          originatingEventId: 'event-2',
          originatingEventType: OriginatingEventType.expertiseEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(communityFromCommunityEvent.originatingEventType, equals(OriginatingEventType.communityEvent));
        expect(communityFromExpertiseEvent.originatingEventType, equals(OriginatingEventType.expertiseEvent));
      });
    });

    group('Member Tracking', () {
      test('should track member IDs', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: ['user-1', 'user-2', 'user-3'],
          memberCount: 3,
        );

        expect(community.memberIds, containsAll(['user-1', 'user-2', 'user-3']));
        expect(community.memberCount, equals(3));
      });

      test('should track member count separately from member IDs list', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: ['user-1', 'user-2'],
          memberCount: 2,
        );

        expect(community.memberIds.length, equals(2));
        expect(community.memberCount, equals(2));
      });

      test('should identify founder correctly', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community.founderId, equals(founder.id));
      });
    });

    group('Event Tracking', () {
      test('should track event IDs', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          eventIds: ['event-1', 'event-2', 'event-3'],
          eventCount: 3,
        );

        expect(community.eventIds, containsAll(['event-1', 'event-2', 'event-3']));
        expect(community.eventCount, equals(3));
      });

      test('should track event count separately from event IDs list', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          eventIds: ['event-1', 'event-2'],
          eventCount: 2,
        );

        expect(community.eventIds.length, equals(2));
        expect(community.eventCount, equals(2));
      });

      test('should track last event timestamp', () {
        final lastEventTime = testDate.add(const Duration(days: 5));
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          lastEventAt: lastEventTime,
        );

        expect(community.lastEventAt, equals(lastEventTime));
      });
    });

    group('Growth Metrics', () {
      test('should track member growth rate', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberGrowthRate: 0.25, // 25% growth
        );

        expect(community.memberGrowthRate, equals(0.25));
      });

      test('should track event growth rate', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          eventGrowthRate: 0.15, // 15% growth
        );

        expect(community.eventGrowthRate, equals(0.15));
      });

      test('should track engagement score', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          engagementScore: 0.75, // 75% engagement
        );

        expect(community.engagementScore, equals(0.75));
        expect(community.engagementScore, greaterThanOrEqualTo(0.0));
        expect(community.engagementScore, lessThanOrEqualTo(1.0));
      });

      test('should track diversity score', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          diversityScore: 0.60, // 60% diversity
        );

        expect(community.diversityScore, equals(0.60));
        expect(community.diversityScore, greaterThanOrEqualTo(0.0));
        expect(community.diversityScore, lessThanOrEqualTo(1.0));
      });

      test('should track activity level', () {
        final activeCommunity = Community(
          id: 'community-1',
          name: 'Active Community',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          activityLevel: ActivityLevel.active,
        );

        final growingCommunity = Community(
          id: 'community-2',
          name: 'Growing Community',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          activityLevel: ActivityLevel.growing,
        );

        final decliningCommunity = Community(
          id: 'community-3',
          name: 'Declining Community',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          activityLevel: ActivityLevel.declining,
        );

        expect(activeCommunity.activityLevel, equals(ActivityLevel.active));
        expect(growingCommunity.activityLevel, equals(ActivityLevel.growing));
        expect(decliningCommunity.activityLevel, equals(ActivityLevel.declining));
      });
    });

    group('Geographic Tracking', () {
      test('should track original locality', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community.originalLocality, equals('Mission District, San Francisco'));
      });

      test('should track current localities', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          currentLocalities: [
            'Mission District, San Francisco',
            'Castro, San Francisco',
            'Haight-Ashbury, San Francisco',
          ],
        );

        expect(community.currentLocalities, containsAll([
          'Mission District, San Francisco',
          'Castro, San Francisco',
          'Haight-Ashbury, San Francisco',
        ]));
      });

      test('should include original locality in current localities by default', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Original locality is tracked separately
        expect(community.originalLocality, equals('Mission District, San Francisco'));
        // Current localities can be empty initially
        expect(community.currentLocalities, isEmpty);
      });
    });

    group('JSON Serialization/Deserialization', () {
      test('should serialize to JSON correctly', () {
        final community = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          description: 'A community for coffee lovers',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: ['user-1', 'user-2'],
          memberCount: 2,
          eventIds: ['event-1', 'event-2'],
          eventCount: 2,
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
          engagementScore: 0.75,
          diversityScore: 0.60,
          activityLevel: ActivityLevel.active,
          currentLocalities: ['Mission District, San Francisco'],
          lastEventAt: testDate.add(const Duration(days: 1)),
        );

        final json = community.toJson();

        expect(json['id'], equals('community-1'));
        expect(json['name'], equals('Coffee Enthusiasts'));
        expect(json['description'], equals('A community for coffee lovers'));
        expect(json['category'], equals('Coffee'));
        expect(json['originatingEventId'], equals(originatingEvent.id));
        expect(json['originatingEventType'], equals('communityEvent'));
        expect(json['founderId'], equals(founder.id));
        expect(json['originalLocality'], equals('Mission District, San Francisco'));
        expect(json['memberIds'], equals(['user-1', 'user-2']));
        expect(json['memberCount'], equals(2));
        expect(json['eventIds'], equals(['event-1', 'event-2']));
        expect(json['eventCount'], equals(2));
        expect(json['memberGrowthRate'], equals(0.25));
        expect(json['eventGrowthRate'], equals(0.15));
        expect(json['engagementScore'], equals(0.75));
        expect(json['diversityScore'], equals(0.60));
        expect(json['activityLevel'], equals('active'));
        expect(json['currentLocalities'], equals(['Mission District, San Francisco']));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'community-1',
          'name': 'Coffee Enthusiasts',
          'description': 'A community for coffee lovers',
          'category': 'Coffee',
          'originatingEventId': originatingEvent.id,
          'originatingEventType': 'communityEvent',
          'founderId': founder.id,
          'originalLocality': 'Mission District, San Francisco',
          'memberIds': ['user-1', 'user-2'],
          'memberCount': 2,
          'eventIds': ['event-1', 'event-2'],
          'eventCount': 2,
          'memberGrowthRate': 0.25,
          'eventGrowthRate': 0.15,
          'engagementScore': 0.75,
          'diversityScore': 0.60,
          'activityLevel': 'active',
          'currentLocalities': ['Mission District, San Francisco'],
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'lastEventAt': testDate.add(const Duration(days: 1)).toIso8601String(),
        };

        final community = Community.fromJson(json);

        expect(community.id, equals('community-1'));
        expect(community.name, equals('Coffee Enthusiasts'));
        expect(community.description, equals('A community for coffee lovers'));
        expect(community.category, equals('Coffee'));
        expect(community.originatingEventId, equals(originatingEvent.id));
        expect(community.originatingEventType, equals(OriginatingEventType.communityEvent));
        expect(community.founderId, equals(founder.id));
        expect(community.originalLocality, equals('Mission District, San Francisco'));
        expect(community.memberIds, equals(['user-1', 'user-2']));
        expect(community.memberCount, equals(2));
        expect(community.eventIds, equals(['event-1', 'event-2']));
        expect(community.eventCount, equals(2));
        expect(community.memberGrowthRate, equals(0.25));
        expect(community.eventGrowthRate, equals(0.15));
        expect(community.engagementScore, equals(0.75));
        expect(community.diversityScore, equals(0.60));
        expect(community.activityLevel, equals(ActivityLevel.active));
        expect(community.currentLocalities, equals(['Mission District, San Francisco']));
      });

      test('should handle JSON roundtrip correctly', () {
        final originalCommunity = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          description: 'A community for coffee lovers',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberIds: ['user-1', 'user-2'],
          memberCount: 2,
          eventIds: ['event-1', 'event-2'],
          eventCount: 2,
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
          engagementScore: 0.75,
          diversityScore: 0.60,
          activityLevel: ActivityLevel.active,
          currentLocalities: ['Mission District, San Francisco'],
          lastEventAt: testDate.add(const Duration(days: 1)),
        );

        final json = originalCommunity.toJson();
        final reconstructed = Community.fromJson(json);

        expect(reconstructed.id, equals(originalCommunity.id));
        expect(reconstructed.name, equals(originalCommunity.name));
        expect(reconstructed.description, equals(originalCommunity.description));
        expect(reconstructed.category, equals(originalCommunity.category));
        expect(reconstructed.originatingEventId, equals(originalCommunity.originatingEventId));
        expect(reconstructed.originatingEventType, equals(originalCommunity.originatingEventType));
        expect(reconstructed.founderId, equals(originalCommunity.founderId));
        expect(reconstructed.originalLocality, equals(originalCommunity.originalLocality));
        expect(reconstructed.memberIds, equals(originalCommunity.memberIds));
        expect(reconstructed.memberCount, equals(originalCommunity.memberCount));
        expect(reconstructed.eventIds, equals(originalCommunity.eventIds));
        expect(reconstructed.eventCount, equals(originalCommunity.eventCount));
        expect(reconstructed.memberGrowthRate, equals(originalCommunity.memberGrowthRate));
        expect(reconstructed.eventGrowthRate, equals(originalCommunity.eventGrowthRate));
        expect(reconstructed.engagementScore, equals(originalCommunity.engagementScore));
        expect(reconstructed.diversityScore, equals(originalCommunity.diversityScore));
        expect(reconstructed.activityLevel, equals(originalCommunity.activityLevel));
        expect(reconstructed.currentLocalities, equals(originalCommunity.currentLocalities));
      });

      test('should handle missing optional fields in JSON', () {
        final minimalJson = {
          'id': 'community-1',
          'name': 'Test Community',
          'category': 'Coffee',
          'originatingEventId': originatingEvent.id,
          'originatingEventType': 'communityEvent',
          'founderId': founder.id,
          'originalLocality': 'Mission District, San Francisco',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final community = Community.fromJson(minimalJson);

        expect(community.id, equals('community-1'));
        expect(community.name, equals('Test Community'));
        expect(community.description, isNull);
        expect(community.memberIds, isEmpty);
        expect(community.memberCount, equals(0));
        expect(community.eventIds, isEmpty);
        expect(community.eventCount, equals(0));
        expect(community.memberGrowthRate, equals(0.0));
        expect(community.eventGrowthRate, equals(0.0));
        expect(community.engagementScore, equals(0.0));
        expect(community.diversityScore, equals(0.0));
        expect(community.activityLevel, equals(ActivityLevel.active));
        expect(community.currentLocalities, isEmpty);
        expect(community.lastEventAt, isNull);
        expect(community.activityLevel, equals(ActivityLevel.active)); // Default is active
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        final community1 = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final community2 = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community1, equals(community2));
      });

      test('should not be equal when properties differ', () {
        final community1 = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final community2 = Community(
          id: 'community-2',
          name: 'Tea Enthusiasts',
          category: 'Tea',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(community1, isNot(equals(community2)));
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated fields', () {
        final original = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          memberCount: 10,
          engagementScore: 0.85,
        );

        expect(updated.id, equals(original.id));
        expect(updated.name, equals('Updated Name'));
        expect(updated.memberCount, equals(10));
        expect(updated.engagementScore, equals(0.85));
        expect(updated.category, equals(original.category));
      });

      test('should preserve original values when fields not specified', () {
        final original = Community(
          id: 'community-1',
          name: 'Coffee Enthusiasts',
          category: 'Coffee',
          originatingEventId: originatingEvent.id,
          originatingEventType: OriginatingEventType.communityEvent,
          founderId: founder.id,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
          memberCount: 5,
          engagementScore: 0.75,
        );

        final updated = original.copyWith(name: 'Updated Name');

        expect(updated.memberCount, equals(5));
        expect(updated.engagementScore, equals(0.75));
        expect(updated.category, equals(original.category));
      });
    });
  });
}

