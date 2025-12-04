import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/club_service.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/club.dart';
import 'package:spots/core/models/club_hierarchy.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ClubService
/// Tests upgrade community to club, leader management, admin management, member roles, permissions
/// 
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
void main() {
  group('ClubService Tests', () {
    late ClubService service;
    late CommunityService communityService;
    late UnifiedUser founder;
    late Community eligibleCommunity;
    late Community ineligibleCommunity;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      communityService = CommunityService();
      service = ClubService(communityService: communityService);
      testDate = TestHelpers.createTestDateTime();

      // Create founder
      founder = ModelFactories.createTestUser(
        id: 'founder-1',
      );

      // Create eligible community (meets upgrade criteria)
      eligibleCommunity = Community(
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
        memberIds: List.generate(12, (i) => 'user-$i'), // 12 members
        memberCount: 12,
        eventIds: ['event-1', 'event-2', 'event-3', 'event-4'], // 4 events
        eventCount: 4,
      );

      // Create ineligible community (doesn't meet criteria)
      ineligibleCommunity = Community(
        id: 'community-2',
        name: 'Small Community',
        description: 'Small community',
        category: 'Coffee',
        originatingEventId: 'event-2',
        originatingEventType: OriginatingEventType.communityEvent,
        founderId: founder.id,
        originalLocality: 'Mission District, San Francisco',
        createdAt: testDate,
        updatedAt: testDate,
        memberIds: ['user-1', 'user-2'], // Only 2 members
        memberCount: 2,
        eventIds: ['event-1'], // Only 1 event
        eventCount: 1,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Upgrade Community to Club', () {
      test('should upgrade eligible community to club', () async {
        final club = await service.upgradeToClub(
          community: eligibleCommunity,
        );

        expect(club, isNotNull);
        expect(club.isClub, isTrue);
        expect(club.id, equals(eligibleCommunity.id));
        expect(club.name, equals(eligibleCommunity.name));
        expect(club.leaders, contains(eligibleCommunity.founderId));
        expect(club.leaders.length, equals(1));
        expect(club.adminTeam, isEmpty);
        expect(club.organizationalMaturity, equals(0.5));
        expect(club.leadershipStability, equals(0.7));
      });

      test('should preserve community history when upgrading', () async {
        final club = await service.upgradeToClub(
          community: eligibleCommunity,
        );

        expect(club.memberIds, equals(eligibleCommunity.memberIds));
        expect(club.memberCount, equals(eligibleCommunity.memberCount));
        expect(club.eventIds, equals(eligibleCommunity.eventIds));
        expect(club.eventCount, equals(eligibleCommunity.eventCount));
        expect(club.category, equals(eligibleCommunity.category));
        expect(club.originalLocality, equals(eligibleCommunity.originalLocality));
      });

      test('should throw error if community has too few members', () async {
        expect(
          () => service.upgradeToClub(
            community: ineligibleCommunity,
            minMembers: 10,
          ),
          throwsException,
        );
      });

      test('should throw error if community has too few events', () async {
        final communityWithFewEvents = eligibleCommunity.copyWith(
          eventCount: 2,
        );

        expect(
          () => service.upgradeToClub(
            community: communityWithFewEvents,
            minEvents: 3,
          ),
          throwsException,
        );
      });

      test('should throw error if community does not need structure', () async {
        expect(
          () => service.upgradeToClub(
            community: eligibleCommunity,
            needsStructure: false,
          ),
          throwsException,
        );
      });

      test('should set founder as initial leader', () async {
        final club = await service.upgradeToClub(
          community: eligibleCommunity,
        );

        expect(club.leaders, contains(eligibleCommunity.founderId));
        expect(club.leaders.length, equals(1));
      });

      test('should create default hierarchy', () async {
        final club = await service.upgradeToClub(
          community: eligibleCommunity,
        );

        expect(club.hierarchy, isNotNull);
        expect(club.hierarchy.rolePermissions, contains(ClubRole.leader));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.admin));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.moderator));
        expect(club.hierarchy.rolePermissions, contains(ClubRole.member));
      });
    });

    group('Leader Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test('should add leader to club', () async {
        const newLeaderId = 'leader-1';

        await service.addLeader(club, newLeaderId);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders, contains(newLeaderId));
        expect(updated.leaders.length, equals(2)); // Founder + new leader
      });

      test('should not add duplicate leader', () async {
        await service.addLeader(club, club.leaders.first);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        // Leader count should not increase
        expect(updated!.leaders.length, equals(club.leaders.length));
      });

      test('should throw error if user is not a member', () async {
        expect(
          () => service.addLeader(club, 'non-member-1'),
          throwsException,
        );
      });

      test('should remove user from admin team when promoting to leader', () async {
        // First add as admin
        const userId = 'user-1';
        await service.addAdmin(club, userId);

        // Then promote to leader
        await service.addLeader(club, userId);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders, contains(userId));
        expect(updated.adminTeam, isNot(contains(userId)));
      });

      test('should remove leader from club', () async {
        const leaderToRemove = 'leader-1';
        await service.addLeader(club, leaderToRemove);

        await service.removeLeader(club, leaderToRemove);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders, isNot(contains(leaderToRemove)));
      });

      test('should not remove non-leader', () async {
        await service.removeLeader(club, 'non-leader-1');

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        // Leader count should not change
        expect(updated!.leaders.length, equals(club.leaders.length));
      });

      test('should throw error when trying to remove founder if only leader', () async {
        // Club starts with founder as only leader
        expect(
          () => service.removeLeader(club, club.founderId),
          throwsException,
        );
      });

      test('should allow removing founder if there are other leaders', () async {
        const otherLeader = 'leader-1';
        await service.addLeader(club, otherLeader);

        await service.removeLeader(club, club.founderId);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders, isNot(contains(club.founderId)));
        expect(updated.leaders, contains(otherLeader));
      });

      test('should get all leaders', () {
        final leaders = service.getLeaders(club);

        expect(leaders, equals(club.leaders));
        expect(leaders.length, equals(club.leaders.length));
      });

      test('should check if user is leader', () {
        expect(service.isLeader(club, club.leaders.first), isTrue);
        expect(service.isLeader(club, 'non-leader-1'), isFalse);
      });
    });

    group('Admin Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test('should add admin to club', () async {
        const newAdminId = 'admin-1';

        await service.addAdmin(club, newAdminId);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.adminTeam, contains(newAdminId));
        expect(updated.adminTeam.length, equals(1));
      });

      test('should not add duplicate admin', () async {
        const adminId = 'admin-1';
        await service.addAdmin(club, adminId);

        await service.addAdmin(club, adminId);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        // Admin count should not increase
        expect(updated!.adminTeam.length, equals(1));
      });

      test('should throw error if user is not a member', () async {
        expect(
          () => service.addAdmin(club, 'non-member-1'),
          throwsException,
        );
      });

      test('should throw error if user is already a leader', () async {
        expect(
          () => service.addAdmin(club, club.leaders.first),
          throwsException,
        );
      });

      test('should remove admin from club', () async {
        const adminToRemove = 'admin-1';
        await service.addAdmin(club, adminToRemove);

        await service.removeAdmin(club, adminToRemove);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.adminTeam, isNot(contains(adminToRemove)));
      });

      test('should not remove non-admin', () async {
        await service.removeAdmin(club, 'non-admin-1');

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        // Admin count should not change
        expect(updated!.adminTeam.length, equals(club.adminTeam.length));
      });

      test('should get all admins', () {
        final admins = service.getAdmins(club);

        expect(admins, equals(club.adminTeam));
        expect(admins.length, equals(club.adminTeam.length));
      });

      test('should check if user is admin', () async {
        const adminId = 'admin-1';
        await service.addAdmin(club, adminId);

        expect(service.isAdmin(club, adminId), isTrue);
        expect(service.isAdmin(club, 'non-admin-1'), isFalse);
      });
    });

    group('Member Role Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test('should assign moderator role to member', () async {
        const memberId = 'user-1';

        await service.assignRole(club, memberId, ClubRole.moderator);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.memberRoles[memberId], equals(ClubRole.moderator));
      });

      test('should assign member role (default)', () async {
        const memberId = 'user-1';

        await service.assignRole(club, memberId, ClubRole.member);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        // Default role, should not be in memberRoles map
        expect(updated!.memberRoles.containsKey(memberId), isFalse);
      });

      test('should throw error if user is not a member', () async {
        expect(
          () => service.assignRole(club, 'non-member-1', ClubRole.moderator),
          throwsException,
        );
      });

      test('should throw error when trying to assign leader role', () async {
        expect(
          () => service.assignRole(club, 'user-1', ClubRole.leader),
          throwsException,
        );
      });

      test('should throw error when trying to assign admin role', () async {
        expect(
          () => service.assignRole(club, 'user-1', ClubRole.admin),
          throwsException,
        );
      });

      test('should remove from leaders/admins when assigning role', () async {
        const userId = 'user-1';
        await service.addLeader(club, userId);

        await service.assignRole(club, userId, ClubRole.moderator);

        final updated = await service.getClubById(club.id);
        expect(updated, isNotNull);
        expect(updated!.leaders, isNot(contains(userId)));
        expect(updated.memberRoles[userId], equals(ClubRole.moderator));
      });

      test('should get member role', () {
        const memberId = 'user-1';
        final role = service.getMemberRole(club, memberId);

        // Default role is member
        expect(role, equals(ClubRole.member));
      });

      test('should get leader role for leader', () {
        final role = service.getMemberRole(club, club.leaders.first);

        expect(role, equals(ClubRole.leader));
      });

      test('should check if member has permission', () {
        // Leader should have all permissions
        expect(
          service.hasPermission(club, club.leaders.first, 'createEvents'),
          isTrue,
        );
        expect(
          service.hasPermission(club, club.leaders.first, 'manageLeaders'),
          isTrue,
        );

        // Member should have basic permissions only
        const memberId = 'user-1';
        expect(
          service.hasPermission(club, memberId, 'createEvents'),
          isTrue,
        );
        expect(
          service.hasPermission(club, memberId, 'manageMembers'),
          isFalse,
        );
      });
    });

    group('Club Management', () {
      late Club club;

      setUp(() async {
        club = await service.upgradeToClub(
          community: eligibleCommunity,
        );
      });

      test('should get club by ID', () async {
        final retrieved = await service.getClubById(club.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(club.id));
        expect(retrieved.name, equals(club.name));
        expect(retrieved.isClub, isTrue);
      });

      test('should return null for non-existent club', () async {
        final retrieved = await service.getClubById('non-existent-id');

        expect(retrieved, isNull);
      });

      test('should get clubs by leader', () async {
        final clubs = await service.getClubsByLeader(club.leaders.first);

        expect(clubs, isNotEmpty);
        expect(clubs.any((c) => c.id == club.id), isTrue);
        expect(clubs.every((c) => c.isLeader(club.leaders.first)), isTrue);
      });

      test('should get clubs by category', () async {
        final clubs = await service.getClubsByCategory('Coffee');

        expect(clubs, isNotEmpty);
        expect(clubs.any((c) => c.id == club.id), isTrue);
        expect(clubs.every((c) => c.category == 'Coffee'), isTrue);
      });

      test('should limit results when getting clubs by category', () async {
        final clubs = await service.getClubsByCategory(
          'Coffee',
          maxResults: 1,
        );

        expect(clubs.length, lessThanOrEqualTo(1));
      });

      test('should update club details', () async {
        final updated = await service.updateClub(
          club: club,
          name: 'Updated Name',
          description: 'Updated Description',
          organizationalMaturity: 0.85,
          leadershipStability: 0.90,
        );

        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals('Updated Description'));
        expect(updated.organizationalMaturity, equals(0.85));
        expect(updated.leadershipStability, equals(0.90));
      });

      test('should update geographic expansion tracking', () async {
        final updated = await service.updateClub(
          club: club,
          expansionLocalities: ['Castro', 'Haight-Ashbury'],
          expansionCities: ['Oakland'],
          coveragePercentage: {
            'locality': 0.50,
            'city': 0.75,
          },
        );

        expect(updated.expansionLocalities, equals(['Castro', 'Haight-Ashbury']));
        expect(updated.expansionCities, equals(['Oakland']));
        expect(updated.coveragePercentage['locality'], equals(0.50));
        expect(updated.coveragePercentage['city'], equals(0.75));
      });

      test('should preserve existing values when updating with null', () async {
        final updated = await service.updateClub(
          club: club,
          name: 'Updated Name',
        );

        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals(club.description));
        expect(updated.organizationalMaturity, equals(club.organizationalMaturity));
      });
    });
  });
}

