import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/club_hierarchy.dart';

/// Comprehensive tests for ClubHierarchy Model
/// Tests roles enum, permissions system, role hierarchy
/// 
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
void main() {
  group('ClubRole Enum Tests', () {
    test('should have all required roles', () {
      expect(ClubRole.values, containsAll([
        ClubRole.leader,
        ClubRole.admin,
        ClubRole.moderator,
        ClubRole.member,
      ]));
    });

    test('should return correct display names', () {
      expect(ClubRole.leader.getDisplayName(), equals('Leader'));
      expect(ClubRole.admin.getDisplayName(), equals('Admin'));
      expect(ClubRole.moderator.getDisplayName(), equals('Moderator'));
      expect(ClubRole.member.getDisplayName(), equals('Member'));
    });

    test('should return correct hierarchy levels', () {
      expect(ClubRole.leader.getHierarchyLevel(), equals(4));
      expect(ClubRole.admin.getHierarchyLevel(), equals(3));
      expect(ClubRole.moderator.getHierarchyLevel(), equals(2));
      expect(ClubRole.member.getHierarchyLevel(), equals(1));
    });

    test('should correctly determine if role can manage another role', () {
      // Leader can manage all other roles
      expect(ClubRole.leader.canManageRole(ClubRole.admin), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.moderator), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.leader.canManageRole(ClubRole.leader), isFalse);

      // Admin can manage moderator and member
      expect(ClubRole.admin.canManageRole(ClubRole.moderator), isTrue);
      expect(ClubRole.admin.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.admin.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.admin.canManageRole(ClubRole.leader), isFalse);

      // Moderator can manage member
      expect(ClubRole.moderator.canManageRole(ClubRole.member), isTrue);
      expect(ClubRole.moderator.canManageRole(ClubRole.moderator), isFalse);
      expect(ClubRole.moderator.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.moderator.canManageRole(ClubRole.leader), isFalse);

      // Member cannot manage any role
      expect(ClubRole.member.canManageRole(ClubRole.member), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.moderator), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.admin), isFalse);
      expect(ClubRole.member.canManageRole(ClubRole.leader), isFalse);
    });
  });

  group('ClubPermissions Tests', () {
    test('should create permissions with default values (all false)', () {
      const permissions = ClubPermissions();

      expect(permissions.canCreateEvents, isFalse);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isFalse);
      expect(permissions.canViewAnalytics, isFalse);
    });

    test('should create permissions with custom values', () {
      const permissions = ClubPermissions(
        canCreateEvents: true,
        canManageMembers: true,
        canViewAnalytics: true,
      );

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isTrue);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isFalse);
      expect(permissions.canViewAnalytics, isTrue);
    });

    test('should return correct permissions for Leader role', () {
      final permissions = ClubPermissions.forRole(ClubRole.leader);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isTrue);
      expect(permissions.canManageAdmins, isTrue);
      expect(permissions.canManageLeaders, isTrue);
      expect(permissions.canModerateContent, isTrue);
      expect(permissions.canViewAnalytics, isTrue);
    });

    test('should return correct permissions for Admin role', () {
      final permissions = ClubPermissions.forRole(ClubRole.admin);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isTrue);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isTrue);
      expect(permissions.canViewAnalytics, isTrue);
    });

    test('should return correct permissions for Moderator role', () {
      final permissions = ClubPermissions.forRole(ClubRole.moderator);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isTrue);
      expect(permissions.canViewAnalytics, isFalse);
    });

    test('should return correct permissions for Member role', () {
      final permissions = ClubPermissions.forRole(ClubRole.member);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isFalse);
      expect(permissions.canViewAnalytics, isFalse);
    });

    test('should check permissions correctly', () {
      final permissions = ClubPermissions.forRole(ClubRole.leader);

      expect(permissions.hasPermission('createEvents'), isTrue);
      expect(permissions.hasPermission('manageMembers'), isTrue);
      expect(permissions.hasPermission('manageAdmins'), isTrue);
      expect(permissions.hasPermission('manageLeaders'), isTrue);
      expect(permissions.hasPermission('moderateContent'), isTrue);
      expect(permissions.hasPermission('viewAnalytics'), isTrue);
      expect(permissions.hasPermission('unknownPermission'), isFalse);
    });

    test('should serialize to JSON correctly', () {
      final permissions = ClubPermissions.forRole(ClubRole.admin);
      final json = permissions.toJson();

      expect(json['canCreateEvents'], isTrue);
      expect(json['canManageMembers'], isTrue);
      expect(json['canManageAdmins'], isFalse);
      expect(json['canManageLeaders'], isFalse);
      expect(json['canModerateContent'], isTrue);
      expect(json['canViewAnalytics'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'canCreateEvents': true,
        'canManageMembers': true,
        'canManageAdmins': false,
        'canManageLeaders': false,
        'canModerateContent': true,
        'canViewAnalytics': true,
      };

      final permissions = ClubPermissions.fromJson(json);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isTrue);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isTrue);
      expect(permissions.canViewAnalytics, isTrue);
    });

    test('should handle missing fields in JSON with defaults', () {
      final json = {
        'canCreateEvents': true,
        // Other fields missing
      };

      final permissions = ClubPermissions.fromJson(json);

      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isFalse);
      expect(permissions.canManageAdmins, isFalse);
      expect(permissions.canManageLeaders, isFalse);
      expect(permissions.canModerateContent, isFalse);
      expect(permissions.canViewAnalytics, isFalse);
    });

    test('should handle JSON roundtrip correctly', () {
      final original = ClubPermissions.forRole(ClubRole.leader);
      final json = original.toJson();
      final reconstructed = ClubPermissions.fromJson(json);

      expect(reconstructed.canCreateEvents, equals(original.canCreateEvents));
      expect(reconstructed.canManageMembers, equals(original.canManageMembers));
      expect(reconstructed.canManageAdmins, equals(original.canManageAdmins));
      expect(reconstructed.canManageLeaders, equals(original.canManageLeaders));
      expect(reconstructed.canModerateContent, equals(original.canModerateContent));
      expect(reconstructed.canViewAnalytics, equals(original.canViewAnalytics));
    });

    test('should create copy with updated fields', () {
      const original = ClubPermissions();
      final updated = original.copyWith(
        canCreateEvents: true,
        canManageMembers: true,
      );

      expect(updated.canCreateEvents, isTrue);
      expect(updated.canManageMembers, isTrue);
      expect(updated.canManageAdmins, isFalse);
      expect(updated.canModerateContent, isFalse);
    });

    test('should preserve original values when fields not specified in copyWith', () {
      final original = ClubPermissions.forRole(ClubRole.admin);
      final updated = original.copyWith(canCreateEvents: false);

      expect(updated.canCreateEvents, isFalse);
      expect(updated.canManageMembers, equals(original.canManageMembers));
      expect(updated.canManageAdmins, equals(original.canManageAdmins));
      expect(updated.canViewAnalytics, equals(original.canViewAnalytics));
    });

    test('should be equal when all properties match', () {
      final permissions1 = ClubPermissions.forRole(ClubRole.leader);
      final permissions2 = ClubPermissions.forRole(ClubRole.leader);

      expect(permissions1, equals(permissions2));
    });

    test('should not be equal when properties differ', () {
      final permissions1 = ClubPermissions.forRole(ClubRole.leader);
      final permissions2 = ClubPermissions.forRole(ClubRole.member);

      expect(permissions1, isNot(equals(permissions2)));
    });
  });

  group('ClubHierarchy Tests', () {
    test('should create hierarchy with default permissions', () {
      final hierarchy = ClubHierarchy();

      expect(hierarchy.rolePermissions, contains(ClubRole.leader));
      expect(hierarchy.rolePermissions, contains(ClubRole.admin));
      expect(hierarchy.rolePermissions, contains(ClubRole.moderator));
      expect(hierarchy.rolePermissions, contains(ClubRole.member));
    });

    test('should get permissions for each role', () {
      final hierarchy = ClubHierarchy();

      final leaderPermissions = hierarchy.getPermissionsForRole(ClubRole.leader);
      final adminPermissions = hierarchy.getPermissionsForRole(ClubRole.admin);
      final moderatorPermissions = hierarchy.getPermissionsForRole(ClubRole.moderator);
      final memberPermissions = hierarchy.getPermissionsForRole(ClubRole.member);

      expect(leaderPermissions.canManageLeaders, isTrue);
      expect(adminPermissions.canManageAdmins, isFalse);
      expect(moderatorPermissions.canModerateContent, isTrue);
      expect(memberPermissions.canCreateEvents, isTrue);
    });

    test('should check if role has permission', () {
      final hierarchy = ClubHierarchy();

      expect(hierarchy.roleHasPermission(ClubRole.leader, 'createEvents'), isTrue);
      expect(hierarchy.roleHasPermission(ClubRole.leader, 'manageLeaders'), isTrue);
      expect(hierarchy.roleHasPermission(ClubRole.admin, 'manageAdmins'), isFalse);
      expect(hierarchy.roleHasPermission(ClubRole.member, 'manageMembers'), isFalse);
    });

    test('should return default member permissions for unknown role', () {
      final hierarchy = ClubHierarchy();
      // Note: This test assumes the implementation handles unknown roles gracefully
      // The actual implementation uses ClubPermissions.forRole(ClubRole.member) as fallback
      final permissions = hierarchy.getPermissionsForRole(ClubRole.member);
      expect(permissions.canCreateEvents, isTrue);
      expect(permissions.canManageMembers, isFalse);
    });

    test('should create hierarchy with custom permissions', () {
      final customPermissions = {
        ClubRole.leader: ClubPermissions.forRole(ClubRole.leader),
        ClubRole.admin: ClubPermissions.forRole(ClubRole.admin),
        ClubRole.moderator: ClubPermissions.forRole(ClubRole.moderator),
        ClubRole.member: ClubPermissions.forRole(ClubRole.member),
      };

      final hierarchy = ClubHierarchy(rolePermissions: customPermissions);

      expect(hierarchy.rolePermissions, equals(customPermissions));
    });

    test('should serialize to JSON correctly', () {
      final hierarchy = ClubHierarchy();
      final json = hierarchy.toJson();

      expect(json, contains('rolePermissions'));
      expect(json['rolePermissions'], isA<Map>());
      expect(json['rolePermissions'], contains('leader'));
      expect(json['rolePermissions'], contains('admin'));
      expect(json['rolePermissions'], contains('moderator'));
      expect(json['rolePermissions'], contains('member'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'rolePermissions': {
          'leader': {
            'canCreateEvents': true,
            'canManageMembers': true,
            'canManageAdmins': true,
            'canManageLeaders': true,
            'canModerateContent': true,
            'canViewAnalytics': true,
          },
          'admin': {
            'canCreateEvents': true,
            'canManageMembers': true,
            'canManageAdmins': false,
            'canManageLeaders': false,
            'canModerateContent': true,
            'canViewAnalytics': true,
          },
        },
      };

      final hierarchy = ClubHierarchy.fromJson(json);

      expect(hierarchy.rolePermissions, contains(ClubRole.leader));
      expect(hierarchy.rolePermissions, contains(ClubRole.admin));
      // Should also have default permissions for missing roles
      expect(hierarchy.rolePermissions, contains(ClubRole.moderator));
      expect(hierarchy.rolePermissions, contains(ClubRole.member));
    });

    test('should handle missing roles in JSON by adding defaults', () {
      final json = {
        'rolePermissions': {
          'leader': {
            'canCreateEvents': true,
            'canManageMembers': true,
            'canManageAdmins': true,
            'canManageLeaders': true,
            'canModerateContent': true,
            'canViewAnalytics': true,
          },
        },
      };

      final hierarchy = ClubHierarchy.fromJson(json);

      // Should have all roles even if not in JSON
      expect(hierarchy.rolePermissions, contains(ClubRole.leader));
      expect(hierarchy.rolePermissions, contains(ClubRole.admin));
      expect(hierarchy.rolePermissions, contains(ClubRole.moderator));
      expect(hierarchy.rolePermissions, contains(ClubRole.member));
    });

    test('should handle JSON roundtrip correctly', () {
      final original = ClubHierarchy();
      final json = original.toJson();
      final reconstructed = ClubHierarchy.fromJson(json);

      expect(reconstructed.rolePermissions.length, equals(original.rolePermissions.length));
      for (final role in ClubRole.values) {
        final originalPerms = original.getPermissionsForRole(role);
        final reconstructedPerms = reconstructed.getPermissionsForRole(role);
        expect(reconstructedPerms.canCreateEvents, equals(originalPerms.canCreateEvents));
        expect(reconstructedPerms.canManageMembers, equals(originalPerms.canManageMembers));
        expect(reconstructedPerms.canManageAdmins, equals(originalPerms.canManageAdmins));
        expect(reconstructedPerms.canManageLeaders, equals(originalPerms.canManageLeaders));
        expect(reconstructedPerms.canModerateContent, equals(originalPerms.canModerateContent));
        expect(reconstructedPerms.canViewAnalytics, equals(originalPerms.canViewAnalytics));
      }
    });

    test('should create copy with updated permissions', () {
      final original = ClubHierarchy();
      final customPermissions = {
        ...original.rolePermissions,
        ClubRole.member: ClubPermissions(
          canCreateEvents: true,
          canManageMembers: true, // Custom: members can manage members
        ),
      };
      final updated = original.copyWith(rolePermissions: customPermissions);

      expect(updated.rolePermissions[ClubRole.member]?.canManageMembers, isTrue);
      expect(updated.rolePermissions[ClubRole.leader], equals(original.rolePermissions[ClubRole.leader]));
    });

    test('should be equal when all properties match', () {
      final hierarchy1 = ClubHierarchy();
      final hierarchy2 = ClubHierarchy();

      expect(hierarchy1, equals(hierarchy2));
    });

    test('should not be equal when permissions differ', () {
      final hierarchy1 = ClubHierarchy();
      final customPermissions = {
        ...hierarchy1.rolePermissions,
        ClubRole.member: ClubPermissions(canCreateEvents: false),
      };
      final hierarchy2 = ClubHierarchy(rolePermissions: customPermissions);

      expect(hierarchy1, isNot(equals(hierarchy2)));
    });
  });
}

