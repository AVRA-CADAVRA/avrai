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
      test('should extend Community model correctly', () {
        final club = Club.fromCommunity(community: baseCommunity);

        expect(club.id, equals(baseCommunity.id));
        expect(club.name, equals(baseCommunity.name));
        expect(club.description, equals(baseCommunity.description));
        expect(club.category, equals(baseCommunity.category));
        expect(club.originatingEventId, equals(baseCommunity.originatingEventId));
        expect(club.originatingEventType, equals(baseCommunity.originatingEventType));
        expect(club.founderId, equals(baseCommunity.founderId));
        expect(club.memberIds, equals(baseCommunity.memberIds));
        expect(club.memberCount, equals(baseCommunity.memberCount));
      });

      test('should preserve all Community properties', () {
        final communityWithMetrics = baseCommunity.copyWith(
          memberGrowthRate: 0.25,
          eventGrowthRate: 0.15,
          engagementScore: 0.75,
          diversityScore: 0.60,
          activityLevel: ActivityLevel.growing,
        );

        final club = Club.fromCommunity(community: communityWithMetrics);

        expect(club.memberGrowthRate, equals(0.25));
        expect(club.eventGrowthRate, equals(0.15));
        expect(club.engagementScore, equals(0.75));
        expect(club.diversityScore, equals(0.60));
        expect(club.activityLevel, equals(ActivityLevel.growing));
      });

      test('should be instance of Community', () {
        final club = Club.fromCommunity(community: baseCommunity);
        expect(club, isA<Community>());
      });
    });

    group('Organizational Structure', () {
      test('should have isClub flag set to true', () {
        final club = Club.fromCommunity(community: baseCommunity);
        expect(club.isClub, isTrue);
      });

      test('should set founder as initial leader by default', () {
        final club = Club.fromCommunity(community: baseCommunity);
        expect(club.leaders, contains(founder.id));
        expect(club.leaders.length, equals(1));
      });

      test('should allow custom leaders', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1', 'leader-2'],
        );

        expect(club.leaders, containsAll(['leader-1', 'leader-2']));
        expect(club.leaders.length, equals(2));
      });

      test('should track admin team', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          adminTeam: ['admin-1', 'admin-2'],
        );

        expect(club.adminTeam, containsAll(['admin-1', 'admin-2']));
        expect(club.adminTeam.length, equals(2));
      });

      test('should have default hierarchy', () {
        final club = Club.fromCommunity(community: baseCommunity);
        expect(club.hierarchy, isNotNull);
        expect(club.hierarchy.rolePermissions, contains(ClubRole.leader));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.admin));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.moderator));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.member));
      });

      test('should allow custom hierarchy', () {
        final customHierarchy = ClubHierarchy();
        final club = Club.fromCommunity(
          community: baseCommunity,
          hierarchy: customHierarchy,
        );

        expect(club.hierarchy, equals(customHierarchy));
      });

      test('should check if has organizational structure', () {
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

        expect(clubWithStructure.hasOrganizationalStructure, isTrue);
        expect(clubWithoutStructure.hasOrganizationalStructure, isFalse);
      });
    });

    group('Member Roles', () {
      test('should track member roles', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
        );

        expect(club.memberRoles['user-1'], equals(ClubRole.moderator));
        expect(club.memberRoles['user-2'], equals(ClubRole.member));
      });

      test('should identify leaders correctly', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1', 'leader-2'],
        );

        expect(club.isLeader('leader-1'), isTrue);
        expect(club.isLeader('leader-2'), isTrue);
        expect(club.isLeader('user-1'), isFalse);
      });

      test('should identify admins correctly', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          adminTeam: ['admin-1', 'admin-2'],
        );

        expect(club.isAdmin('admin-1'), isTrue);
        expect(club.isAdmin('admin-2'), isTrue);
        expect(club.isAdmin('user-1'), isFalse);
      });

      test('should identify moderators correctly', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          memberRoles: {
            'user-1': ClubRole.moderator,
          },
        );

        expect(club.isModerator('user-1'), isTrue);
        expect(club.isModerator('user-2'), isFalse);
      });

      test('should get member role correctly', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
        );

        expect(club.getMemberRole('leader-1'), equals(ClubRole.leader));
        expect(club.getMemberRole('admin-1'), equals(ClubRole.admin));
        expect(club.getMemberRole('user-1'), equals(ClubRole.moderator));
        expect(club.getMemberRole('user-2'), equals(ClubRole.member));
        expect(club.getMemberRole('unknown-user'), equals(ClubRole.member)); // Default
      });

      test('should track pending members', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          pendingMembers: ['pending-1', 'pending-2'],
        );

        expect(club.pendingMembers, containsAll(['pending-1', 'pending-2']));
        expect(club.hasPendingMembership('pending-1'), isTrue);
        expect(club.hasPendingMembership('user-1'), isFalse);
      });

      test('should track banned members', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          bannedMembers: ['banned-1', 'banned-2'],
        );

        expect(club.bannedMembers, containsAll(['banned-1', 'banned-2']));
        expect(club.isBanned('banned-1'), isTrue);
        expect(club.isBanned('user-1'), isFalse);
      });
    });

    group('Permissions', () {
      test('should check if user has permission', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
        );

        // Leader has all permissions
        expect(club.hasPermission('leader-1', 'createEvents'), isTrue);
        expect(club.hasPermission('leader-1', 'manageLeaders'), isTrue);

        // Admin has some permissions
        expect(club.hasPermission('admin-1', 'createEvents'), isTrue);
        expect(club.hasPermission('admin-1', 'manageAdmins'), isFalse);

        // Moderator has limited permissions
        expect(club.hasPermission('user-1', 'createEvents'), isTrue);
        expect(club.hasPermission('user-1', 'manageMembers'), isFalse);

        // Member has basic permissions
        expect(club.hasPermission('user-2', 'createEvents'), isTrue);
        expect(club.hasPermission('user-2', 'manageMembers'), isFalse);
      });

      test('should return false for unknown user', () {
        final club = Club.fromCommunity(community: baseCommunity);
        expect(club.hasPermission('unknown-user', 'createEvents'), isFalse);
      });

      test('should get permissions for user', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
        );

        final permissions = club.getPermissionsForUser('leader-1');
        expect(permissions.canCreateEvents, isTrue);
        expect(permissions.canManageLeaders, isTrue);
        expect(permissions.canViewAnalytics, isTrue);
      });

      test('should return empty permissions for unknown user', () {
        final club = Club.fromCommunity(community: baseCommunity);
        final permissions = club.getPermissionsForUser('unknown-user');
        expect(permissions.canCreateEvents, isFalse);
        expect(permissions.canManageMembers, isFalse);
      });

      test('should check if user can manage another user', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
            'user-2': ClubRole.member,
          },
        );

        // Leader can manage all
        expect(club.canManageUser('leader-1', 'admin-1'), isTrue);
        expect(club.canManageUser('leader-1', 'user-1'), isTrue);
        expect(club.canManageUser('leader-1', 'user-2'), isTrue);

        // Admin can manage moderator and member
        expect(club.canManageUser('admin-1', 'user-1'), isTrue);
        expect(club.canManageUser('admin-1', 'user-2'), isTrue);
        expect(club.canManageUser('admin-1', 'leader-1'), isFalse);

        // Moderator can manage member
        expect(club.canManageUser('user-1', 'user-2'), isTrue);
        expect(club.canManageUser('user-1', 'admin-1'), isFalse);

        // Member cannot manage anyone
        expect(club.canManageUser('user-2', 'user-1'), isFalse);
      });
    });

    group('Club Metrics', () {
      test('should track organizational maturity', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          organizationalMaturity: 0.75,
        );

        expect(club.organizationalMaturity, equals(0.75));
        expect(club.isMature, isTrue); // >= 0.7
      });

      test('should track leadership stability', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          leadershipStability: 0.80,
        );

        expect(club.leadershipStability, equals(0.80));
        expect(club.hasStableLeadership, isTrue); // >= 0.7
      });

      test('should identify mature clubs', () {
        final matureClub = Club.fromCommunity(
          community: baseCommunity,
          organizationalMaturity: 0.75,
        );

        final immatureClub = Club.fromCommunity(
          community: baseCommunity,
          organizationalMaturity: 0.50,
        );

        expect(matureClub.isMature, isTrue);
        expect(immatureClub.isMature, isFalse);
      });

      test('should identify stable leadership', () {
        final stableClub = Club.fromCommunity(
          community: baseCommunity,
          leadershipStability: 0.80,
        );

        final unstableClub = Club.fromCommunity(
          community: baseCommunity,
          leadershipStability: 0.50,
        );

        expect(stableClub.hasStableLeadership, isTrue);
        expect(unstableClub.hasStableLeadership, isFalse);
      });
    });

    group('Geographic Expansion Tracking', () {
      test('should track expansion localities', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          expansionLocalities: [
            'Castro, San Francisco',
            'Haight-Ashbury, San Francisco',
          ],
        );

        expect(club.expansionLocalities, containsAll([
          'Castro, San Francisco',
          'Haight-Ashbury, San Francisco',
        ]));
      });

      test('should track expansion cities', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          expansionCities: ['Oakland', 'Berkeley'],
        );

        expect(club.expansionCities, containsAll(['Oakland', 'Berkeley']));
      });

      test('should track coverage percentage', () {
        final club = Club.fromCommunity(
          community: baseCommunity,
          coveragePercentage: {
            'locality': 0.50,
            'city': 0.75,
            'state': 0.30,
          },
        );

        expect(club.coveragePercentage['locality'], equals(0.50));
        expect(club.coveragePercentage['city'], equals(0.75));
        expect(club.coveragePercentage['state'], equals(0.30));
      });
    });

    group('JSON Serialization/Deserialization', () {
      test('should serialize to JSON correctly', () {
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

        expect(json['isClub'], isTrue);
        expect(json['leaders'], equals(['leader-1']));
        expect(json['adminTeam'], equals(['admin-1']));
        expect(json['organizationalMaturity'], equals(0.75));
        expect(json['leadershipStability'], equals(0.80));
        expect(json['hierarchy'], isNotNull);
        expect(json['memberRoles'], isA<Map>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'community-1',
          'name': 'Coffee Enthusiasts',
          'category': 'Coffee',
          'originatingEventId': 'event-1',
          'originatingEventType': 'communityEvent',
          'founderId': 'founder-1',
          'originalLocality': 'Mission District, San Francisco',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'isClub': true,
          'leaders': ['leader-1'],
          'adminTeam': ['admin-1'],
          'hierarchy': {
            'rolePermissions': {},
          },
          'memberRoles': {
            'user-1': 'moderator',
          },
          'organizationalMaturity': 0.75,
          'leadershipStability': 0.80,
        };

        final club = Club.fromJson(json);

        expect(club.isClub, isTrue);
        expect(club.leaders, equals(['leader-1']));
        expect(club.adminTeam, equals(['admin-1']));
        expect(club.memberRoles['user-1'], equals(ClubRole.moderator));
        expect(club.organizationalMaturity, equals(0.75));
        expect(club.leadershipStability, equals(0.80));
      });

      test('should handle JSON roundtrip correctly', () {
        final originalClub = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          adminTeam: ['admin-1'],
          memberRoles: {
            'user-1': ClubRole.moderator,
          },
          organizationalMaturity: 0.75,
          leadershipStability: 0.80,
        );

        final json = originalClub.toJson();
        final reconstructed = Club.fromJson(json);

        expect(reconstructed.id, equals(originalClub.id));
        expect(reconstructed.name, equals(originalClub.name));
        expect(reconstructed.isClub, equals(originalClub.isClub));
        expect(reconstructed.leaders, equals(originalClub.leaders));
        expect(reconstructed.adminTeam, equals(originalClub.adminTeam));
        expect(reconstructed.organizationalMaturity, equals(originalClub.organizationalMaturity));
        expect(reconstructed.leadershipStability, equals(originalClub.leadershipStability));
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated fields', () {
        final original = Club.fromCommunity(community: baseCommunity);
        final updated = original.copyWith(
          name: 'Updated Name',
          leaders: ['new-leader'],
          organizationalMaturity: 0.90,
        );

        expect(updated.id, equals(original.id));
        expect(updated.name, equals('Updated Name'));
        expect(updated.leaders, equals(['new-leader']));
        expect(updated.organizationalMaturity, equals(0.90));
        expect(updated.category, equals(original.category));
      });

      test('should preserve original values when fields not specified', () {
        final original = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
          organizationalMaturity: 0.75,
        );

        final updated = original.copyWith(name: 'Updated Name');

        expect(updated.leaders, equals(original.leaders));
        expect(updated.organizationalMaturity, equals(original.organizationalMaturity));
        expect(updated.category, equals(original.category));
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        final club1 = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
        );

        final club2 = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
        );

        expect(club1, equals(club2));
      });

      test('should not be equal when properties differ', () {
        final club1 = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-1'],
        );

        final club2 = Club.fromCommunity(
          community: baseCommunity,
          leaders: ['leader-2'],
        );

        expect(club1, isNot(equals(club2)));
      });
    });
  });
}

