import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/club.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/club_hierarchy.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Club Model
/// Tests extends Community correctly, organizational structure, member roles, permissions
///
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
void main() {
  group('Club Model Tests', () {
    late UnifiedUser founder;
    late Community baseCommunity;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();

      // Create founder
      founder = ModelFactories.createTestUser(
        id: 'founder-1',
      );

      // Create base community
      baseCommunity = Community(
        id: 'community-1',
        name: 'Coffee Enthusiasts',
        description: 'A community for coffee lovers',
        category: 'Coffee',
        originatingEventId: 'event-1',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: founder.id,
        originalLocality: 'Mission District, San Francisco',
        createdAt: testDate,
        updatedAt: testDate,
        memberIds: ['user-1', 'user-2', 'user-3'],
        memberCount: 3,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Extends Community', () {
      test('should correctly extend Community and preserve business properties',
          () {
        // Test business logic: inheritance and property preservation
        final communityWithMetrics = baseCommunity.copyWith(
          memberGrowthRate: 0.25,
          engagementScore: 0.75,
          activityLevel: ActivityLevel.growing,
        );

        final club = Club.fromCommunity(community: communityWithMetrics);

        // Test critical business properties preserved
        expect(club, isA<Community>());
        expect(club.memberGrowthRate, equals(0.25));
        expect(club.activityLevel, equals(ActivityLevel.growing));
      });
    });

    group('Organizational Structure', () {
      test(
          'should correctly identify organizational structure state and set founder as initial leader by default',
          () {
        // Test business logic: structure detection and default leader assignment
        final clubWithStructure = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
        );
        final clubWithoutStructure = Club.fromCommunity(
          community: baseCommunity,
          leaders: [],
          adminTeam: [],
        );
        final defaultClub = Club.fromCommunity(community: baseCommunity);

        expect(clubWithStructure.isClub, isTrue);
        expect(clubWithStructure.hasOrganizationalStructure, isTrue);
        expect(clubWithoutStructure.hasOrganizationalStructure, isFalse);
        expect(defaultClub.leaders, contains(founder.id));
      });
    });

    group('Member Roles', () {
      test(
          'should correctly identify and retrieve member roles and track membership states',
          () {
        // Test business logic: role identification and membership tracking
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
          pendingMembers: ['pending-1'],
          bannedMembers: ['banned-1'],
        );

        expect(club.isLeader('leader-1'), isTrue);
        expect(club.isAdmin('admin-1'), isTrue);
        expect(club.isModerator('user-1'), isTrue);
        expect(club.getMemberRole('leader-1'), equals(ClubRole.leader));
        expect(club.getMemberRole('unknown-user'), isNull);
        expect(club.hasPendingMembership('pending-1'), isTrue);
        expect(club.isBanned('banned-1'), isTrue);
        expect(club.hasPendingMembership('user-1'), isFalse);
      });
    });

    group('Permissions', () {
      test(
          'should correctly check permissions based on role hierarchy and determine user management permissions',
          () {
        // Test business logic: permission checking and management hierarchy
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
        );

        // Test role-based permissions
        expect(club.hasPermission('leader-1', 'manageLeaders'), isTrue);
        expect(club.hasPermission('admin-1', 'manageAdmins'), isFalse);
        expect(club.hasPermission('user-1', 'manageMembers'), isFalse);
        expect(club.hasPermission('unknown-user', 'createEvents'), isFalse);

        // Test management hierarchy
        expect(club.canManageUser('leader-1', 'admin-1'), isTrue);
        expect(club.canManageUser('admin-1', 'user-1'), isTrue);
        expect(club.canManageUser('admin-1', 'leader-1'), isFalse);
        expect(club.canManageUser('user-2', 'user-1'), isFalse);
      });
    });

    group('Club Metrics', () {
      test('should correctly identify maturity and stability states', () {
        // Test business logic: maturity thresholds (>= 0.7)
        final matureClub = Club.fromCommunity(
          community: baseCommunity,
          organizationalMaturity: 0.75,
          leadershipStability: 0.80,
        );
        final immatureClub = Club.fromCommunity(
          community: baseCommunity,
          organizationalMaturity: 0.50,
          leadershipStability: 0.50,
        );

        expect(matureClub.isMature, isTrue);
        expect(matureClub.hasStableLeadership, isTrue);
        expect(immatureClub.isMature, isFalse);
        expect(immatureClub.hasStableLeadership, isFalse);
      });
    });

    // Removed: Geographic Expansion Tracking group
    // These tests only verified map/list storage, not business logic

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with nested club structure correctly',
          () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
          },
          organizationalMaturity: 0.75,
          leadershipStability: 0.80,
        );

        final json = club.toJson();
        final restored = Club.fromJson(json);

        // Test nested structures preserved (business logic)
        expect(restored.isClub, isTrue);
        expect(restored.leaders, equals(['leader-1']));
        expect(restored.memberRoles['user-1'], equals(ClubRole.moderator));
        expect(restored.isMature, isTrue);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = Club.fromCommunity(community: baseCommunity);
        final updated = original.copyWith(
          name: 'Updated Name',
          leaders: ['new-leader'],
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('Updated Name')));
        expect(updated.name, equals('Updated Name'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
