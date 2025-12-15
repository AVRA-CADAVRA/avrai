import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

/// Club Hierarchy Model
/// 
/// Represents the organizational structure of a club (roles, permissions).
/// 
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth
/// 
/// **Key Features:**
/// - Roles enum (Leader, Admin, Moderator, Member)
/// - Permissions system (canCreateEvents, canManageMembers, etc.)
/// - Role hierarchy (Leader > Admin > Moderator > Member)
/// 
/// **Role Hierarchy:**
/// - Leader: Founders, primary organizers (full permissions)
/// - Admin: Managers, moderators (high permissions)
/// - Moderator: Event organizers, content moderators (medium permissions)
/// - Member: Regular members (basic permissions)

/// Club Role
enum ClubRole {
  leader,
  admin,
  moderator,
  member;

  /// Get display name
  String getDisplayName() {
    switch (this) {
      case ClubRole.leader:
        return 'Leader';
      case ClubRole.admin:
        return 'Admin';
      case ClubRole.moderator:
        return 'Moderator';
      case ClubRole.member:
        return 'Member';
    }
  }

  /// Get role hierarchy level (higher = more permissions)
  int getHierarchyLevel() {
    switch (this) {
      case ClubRole.leader:
        return 4;
      case ClubRole.admin:
        return 3;
      case ClubRole.moderator:
        return 2;
      case ClubRole.member:
        return 1;
    }
  }

  /// Check if this role can manage another role
  bool canManageRole(ClubRole otherRole) {
    return getHierarchyLevel() > otherRole.getHierarchyLevel();
  }
}

/// Club Permissions
class ClubPermissions extends Equatable {
  /// Can create events
  final bool canCreateEvents;
  
  /// Can manage members (add/remove members)
  final bool canManageMembers;
  
  /// Can manage admins (promote to admin)
  final bool canManageAdmins;
  
  /// Can manage leaders (promote to leader)
  final bool canManageLeaders;
  
  /// Can moderate content
  final bool canModerateContent;
  
  /// Can view analytics
  final bool canViewAnalytics;

  const ClubPermissions({
    this.canCreateEvents = false,
    this.canManageMembers = false,
    this.canManageAdmins = false,
    this.canManageLeaders = false,
    this.canModerateContent = false,
    this.canViewAnalytics = false,
  });

  /// Get permissions for a role
  static ClubPermissions forRole(ClubRole role) {
    switch (role) {
      case ClubRole.leader:
        return const ClubPermissions(
          canCreateEvents: true,
          canManageMembers: true,
          canManageAdmins: true,
          canManageLeaders: true,
          canModerateContent: true,
          canViewAnalytics: true,
        );
      case ClubRole.admin:
        return const ClubPermissions(
          canCreateEvents: true,
          canManageMembers: true,
          canManageAdmins: false,
          canManageLeaders: false,
          canModerateContent: true,
          canViewAnalytics: true,
        );
      case ClubRole.moderator:
        return const ClubPermissions(
          canCreateEvents: true,
          canManageMembers: false,
          canManageAdmins: false,
          canManageLeaders: false,
          canModerateContent: true,
          canViewAnalytics: false,
        );
      case ClubRole.member:
        return const ClubPermissions(
          canCreateEvents: true,
          canManageMembers: false,
          canManageAdmins: false,
          canManageLeaders: false,
          canModerateContent: false,
          canViewAnalytics: false,
        );
    }
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'createEvents':
        return canCreateEvents;
      case 'manageMembers':
        return canManageMembers;
      case 'manageAdmins':
        return canManageAdmins;
      case 'manageLeaders':
        return canManageLeaders;
      case 'moderateContent':
        return canModerateContent;
      case 'viewAnalytics':
        return canViewAnalytics;
      default:
        return false;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'canCreateEvents': canCreateEvents,
      'canManageMembers': canManageMembers,
      'canManageAdmins': canManageAdmins,
      'canManageLeaders': canManageLeaders,
      'canModerateContent': canModerateContent,
      'canViewAnalytics': canViewAnalytics,
    };
  }

  /// Create from JSON
  factory ClubPermissions.fromJson(Map<String, dynamic> json) {
    return ClubPermissions(
      canCreateEvents: json['canCreateEvents'] as bool? ?? false,
      canManageMembers: json['canManageMembers'] as bool? ?? false,
      canManageAdmins: json['canManageAdmins'] as bool? ?? false,
      canManageLeaders: json['canManageLeaders'] as bool? ?? false,
      canModerateContent: json['canModerateContent'] as bool? ?? false,
      canViewAnalytics: json['canViewAnalytics'] as bool? ?? false,
    );
  }

  /// Copy with method
  ClubPermissions copyWith({
    bool? canCreateEvents,
    bool? canManageMembers,
    bool? canManageAdmins,
    bool? canManageLeaders,
    bool? canModerateContent,
    bool? canViewAnalytics,
  }) {
    return ClubPermissions(
      canCreateEvents: canCreateEvents ?? this.canCreateEvents,
      canManageMembers: canManageMembers ?? this.canManageMembers,
      canManageAdmins: canManageAdmins ?? this.canManageAdmins,
      canManageLeaders: canManageLeaders ?? this.canManageLeaders,
      canModerateContent: canModerateContent ?? this.canModerateContent,
      canViewAnalytics: canViewAnalytics ?? this.canViewAnalytics,
    );
  }

  @override
  List<Object?> get props => [
        canCreateEvents,
        canManageMembers,
        canManageAdmins,
        canManageLeaders,
        canModerateContent,
        canViewAnalytics,
      ];
}

/// Club Hierarchy
/// 
/// Represents the organizational structure of a club.
class ClubHierarchy extends Equatable {
  /// Default permissions for each role
  final Map<ClubRole, ClubPermissions> rolePermissions;

  ClubHierarchy({
    Map<ClubRole, ClubPermissions>? rolePermissions,
  }) : rolePermissions = rolePermissions ?? _defaultRolePermissions;

  static final Map<ClubRole, ClubPermissions> _defaultRolePermissions = {
    ClubRole.leader: ClubPermissions.forRole(ClubRole.leader),
    ClubRole.admin: ClubPermissions.forRole(ClubRole.admin),
    ClubRole.moderator: ClubPermissions.forRole(ClubRole.moderator),
    ClubRole.member: ClubPermissions.forRole(ClubRole.member),
  };

  /// Get permissions for a role
  ClubPermissions getPermissionsForRole(ClubRole role) {
    return rolePermissions[role] ?? ClubPermissions.forRole(ClubRole.member);
  }

  /// Check if a role has a permission
  bool roleHasPermission(ClubRole role, String permission) {
    final permissions = getPermissionsForRole(role);
    return permissions.hasPermission(permission);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'rolePermissions': rolePermissions.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      ),
    };
  }

  /// Create from JSON
  factory ClubHierarchy.fromJson(Map<String, dynamic> json) {
    final rawRolePermissions = json['rolePermissions'];
    final rolePermissionsMap = rawRolePermissions is Map
        ? Map<String, dynamic>.from(rawRolePermissions)
        : null;
    final rolePermissions = <ClubRole, ClubPermissions>{};

    if (rolePermissionsMap != null) {
      rolePermissionsMap.forEach((key, value) {
        assert(() {
          // #region agent log
          try {
            const debugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
            final payload = <String, dynamic>{
              'sessionId': 'debug-session',
              'runId': 'pre-fix',
              'hypothesisId': 'H-club-json',
              'location': 'club_hierarchy.dart:fromJson',
              'message': 'Parsing rolePermissions entry',
              'data': {
                'keyType': key.runtimeType.toString(),
                'valueType': value.runtimeType.toString(),
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            File(debugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
          } catch (_) {}
          // #endregion
          return true;
        }());

        final role = ClubRole.values.firstWhere(
          (r) => r.name == key,
          orElse: () => ClubRole.member,
        );
        final valueMap = value is Map<String, dynamic>
            ? value
            : (value is Map ? Map<String, dynamic>.from(value) : null);
        rolePermissions[role] = ClubPermissions.fromJson(valueMap ?? const {});
      });
    }

    // Ensure all roles have permissions
    for (final role in ClubRole.values) {
      if (!rolePermissions.containsKey(role)) {
        rolePermissions[role] = ClubPermissions.forRole(role);
      }
    }

    return ClubHierarchy(rolePermissions: rolePermissions);
  }

  /// Copy with method
  ClubHierarchy copyWith({
    Map<ClubRole, ClubPermissions>? rolePermissions,
  }) {
    return ClubHierarchy(
      rolePermissions: rolePermissions ?? this.rolePermissions,
    );
  }

  @override
  List<Object?> get props => [rolePermissions];
}

