import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/club_hierarchy.dart';
import 'package:spots/core/models/geographic_expansion.dart';

/// Club Model
/// 
/// Extends Community model to add organizational structure (leaders, admins, hierarchy).
/// 
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth and geographic expansion
/// 
/// **Key Features:**
/// - Extends Community model
/// - Organizational structure (leaders, admin team, hierarchy)
/// - Member management (member roles, pending members, banned members)
/// - Club-specific metrics (organizational maturity, leadership stability)
/// - Geographic expansion tracking (for Week 30 - 75% coverage rule)
/// 
/// **Upgrade Path:**
/// - Communities upgrade to clubs when:
///   - Community has X+ members
///   - Community has hosted Y+ events
///   - Community has stable leadership
///   - Community needs organizational structure
class Club extends Community {
  /// Club flag (always true for Club)
  final bool isClub;
  
  /// Organizational structure
  final List<String> leaders; // Leader user IDs (founders, primary organizers)
  final List<String> adminTeam; // Admin user IDs (managers, moderators)
  final ClubHierarchy hierarchy; // Organizational structure (roles, permissions)
  
  /// Member management
  final Map<String, ClubRole> memberRoles; // Map of user ID → role
  final List<String> pendingMembers; // List of pending member requests
  final List<String> bannedMembers; // List of banned member IDs
  
  /// Club-specific metrics
  final double organizationalMaturity; // How structured the club is (0.0 to 1.0)
  final double leadershipStability; // Stability of leadership (0.0 to 1.0)
  
  /// Geographic expansion tracking (for Week 30)
  final List<String> expansionLocalities; // Localities where club has expanded
  final List<String> expansionCities; // Cities where club has expanded
  final Map<String, double> coveragePercentage; // Coverage percentage for each geographic level
  final GeographicExpansion? geographicExpansion; // Full expansion tracking object
  
  /// Leader expertise tracking
  /// Map of leader ID → expertise map (category → level)
  final Map<String, Map<String, String>> leaderExpertise;

  Club({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    required super.originatingEventId,
    required super.originatingEventType,
    super.memberIds,
    super.memberCount,
    required super.founderId,
    super.eventIds,
    super.eventCount,
    super.memberGrowthRate,
    super.eventGrowthRate,
    required super.createdAt,
    super.lastEventAt,
    super.engagementScore,
    super.diversityScore,
    super.activityLevel,
    required super.originalLocality,
    super.currentLocalities,
    required super.updatedAt,
    this.isClub = true,
    this.leaders = const [],
    this.adminTeam = const [],
    ClubHierarchy? hierarchy,
    this.memberRoles = const {},
    this.pendingMembers = const [],
    this.bannedMembers = const [],
    this.organizationalMaturity = 0.0,
    this.leadershipStability = 0.0,
    this.expansionLocalities = const [],
    this.expansionCities = const [],
    this.coveragePercentage = const {},
    this.geographicExpansion,
    this.leaderExpertise = const {},
  }) : hierarchy = hierarchy ?? ClubHierarchy();

  /// Create Club from Community
  factory Club.fromCommunity({
    required Community community,
    List<String>? leaders,
    List<String>? adminTeam,
    ClubHierarchy? hierarchy,
    Map<String, ClubRole>? memberRoles,
    List<String>? pendingMembers,
    List<String>? bannedMembers,
    double? organizationalMaturity,
    double? leadershipStability,
    List<String>? expansionLocalities,
    List<String>? expansionCities,
    Map<String, double>? coveragePercentage,
  }) {
    // Set founder as initial leader if no leaders specified
    final initialLeaders = leaders ?? [community.founderId];
    
    return Club(
      id: community.id,
      name: community.name,
      description: community.description,
      category: community.category,
      originatingEventId: community.originatingEventId,
      originatingEventType: community.originatingEventType,
      memberIds: community.memberIds,
      memberCount: community.memberCount,
      founderId: community.founderId,
      eventIds: community.eventIds,
      eventCount: community.eventCount,
      memberGrowthRate: community.memberGrowthRate,
      eventGrowthRate: community.eventGrowthRate,
      createdAt: community.createdAt,
      lastEventAt: community.lastEventAt,
      engagementScore: community.engagementScore,
      diversityScore: community.diversityScore,
      activityLevel: community.activityLevel,
      originalLocality: community.originalLocality,
      currentLocalities: community.currentLocalities,
      updatedAt: community.updatedAt,
      leaders: initialLeaders,
      adminTeam: adminTeam ?? [],
      hierarchy: hierarchy ?? ClubHierarchy(),
      memberRoles: memberRoles ?? {},
      pendingMembers: pendingMembers ?? [],
      bannedMembers: bannedMembers ?? [],
      organizationalMaturity: organizationalMaturity ?? 0.0,
      leadershipStability: leadershipStability ?? 0.0,
      expansionLocalities: expansionLocalities ?? [],
      expansionCities: expansionCities ?? [],
      coveragePercentage: coveragePercentage ?? {},
      geographicExpansion: null, // Will be set when expansion is tracked
      leaderExpertise: const {},
    );
  }

  /// Check if user is a leader
  bool isLeader(String userId) {
    return leaders.contains(userId);
  }

  /// Check if user is an admin
  bool isAdmin(String userId) {
    return adminTeam.contains(userId);
  }

  /// Check if user is a moderator
  bool isModerator(String userId) {
    final role = memberRoles[userId];
    return role == ClubRole.moderator;
  }

  /// Get user's role in the club
  ClubRole? getMemberRole(String userId) {
    if (isLeader(userId)) return ClubRole.leader;
    if (isAdmin(userId)) return ClubRole.admin;
    return memberRoles[userId] ?? ClubRole.member;
  }

  /// Check if user has permission
  bool hasPermission(String userId, String permission) {
    final role = getMemberRole(userId);
    if (role == null) return false;
    return hierarchy.roleHasPermission(role, permission);
  }

  /// Check if user can manage another user
  bool canManageUser(String managerId, String targetUserId) {
    final managerRole = getMemberRole(managerId);
    final targetRole = getMemberRole(targetUserId);
    
    if (managerRole == null || targetRole == null) return false;
    
    return managerRole.canManageRole(targetRole);
  }

  /// Check if user is banned
  bool isBanned(String userId) {
    return bannedMembers.contains(userId);
  }

  /// Check if user has pending membership
  bool hasPendingMembership(String userId) {
    return pendingMembers.contains(userId);
  }

  /// Get permissions for a user
  ClubPermissions getPermissionsForUser(String userId) {
    final role = getMemberRole(userId);
    if (role == null) return const ClubPermissions();
    return hierarchy.getPermissionsForRole(role);
  }

  /// Check if club has organizational structure
  bool get hasOrganizationalStructure {
    return leaders.isNotEmpty || adminTeam.isNotEmpty;
  }

  /// Check if club is mature (organizational maturity >= 0.7)
  bool get isMature {
    return organizationalMaturity >= 0.7;
  }

  /// Check if leadership is stable (leadership stability >= 0.7)
  bool get hasStableLeadership {
    return leadershipStability >= 0.7;
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'isClub': isClub,
      'leaders': leaders,
      'adminTeam': adminTeam,
      'hierarchy': hierarchy.toJson(),
      'memberRoles': memberRoles.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'pendingMembers': pendingMembers,
      'bannedMembers': bannedMembers,
      'organizationalMaturity': organizationalMaturity,
      'leadershipStability': leadershipStability,
      'expansionLocalities': expansionLocalities,
      'expansionCities': expansionCities,
      'coveragePercentage': coveragePercentage,
      'geographicExpansion': geographicExpansion?.toJson(),
      'leaderExpertise': leaderExpertise,
    });
    return baseJson;
  }

  /// Create from JSON
  factory Club.fromJson(Map<String, dynamic> json) {
    final community = Community.fromJson(json);
    
    final memberRolesMap = json['memberRoles'] as Map<String, dynamic>?;
    final memberRoles = <String, ClubRole>{};
    if (memberRolesMap != null) {
      memberRolesMap.forEach((key, value) {
        final role = ClubRole.values.firstWhere(
          (r) => r.name == value,
          orElse: () => ClubRole.member,
        );
        memberRoles[key] = role;
      });
    }

    final coveragePercentageMap = json['coveragePercentage'] as Map<String, dynamic>?;
    final coveragePercentage = <String, double>{};
    if (coveragePercentageMap != null) {
      coveragePercentageMap.forEach((key, value) {
        coveragePercentage[key] = (value as num).toDouble();
      });
    }

    return Club(
      id: community.id,
      name: community.name,
      description: community.description,
      category: community.category,
      originatingEventId: community.originatingEventId,
      originatingEventType: community.originatingEventType,
      memberIds: community.memberIds,
      memberCount: community.memberCount,
      founderId: community.founderId,
      eventIds: community.eventIds,
      eventCount: community.eventCount,
      memberGrowthRate: community.memberGrowthRate,
      eventGrowthRate: community.eventGrowthRate,
      createdAt: community.createdAt,
      lastEventAt: community.lastEventAt,
      engagementScore: community.engagementScore,
      diversityScore: community.diversityScore,
      activityLevel: community.activityLevel,
      originalLocality: community.originalLocality,
      currentLocalities: community.currentLocalities,
      updatedAt: community.updatedAt,
      leaders: List<String>.from(json['leaders'] as List? ?? []),
      adminTeam: List<String>.from(json['adminTeam'] as List? ?? []),
      hierarchy: json['hierarchy'] != null
          ? ClubHierarchy.fromJson(json['hierarchy'] as Map<String, dynamic>)
          : ClubHierarchy(),
      memberRoles: memberRoles,
      pendingMembers: List<String>.from(json['pendingMembers'] as List? ?? []),
      bannedMembers: List<String>.from(json['bannedMembers'] as List? ?? []),
      organizationalMaturity:
          (json['organizationalMaturity'] as num?)?.toDouble() ?? 0.0,
      leadershipStability:
          (json['leadershipStability'] as num?)?.toDouble() ?? 0.0,
      expansionLocalities:
          List<String>.from(json['expansionLocalities'] as List? ?? []),
      expansionCities: List<String>.from(json['expansionCities'] as List? ?? []),
      coveragePercentage: coveragePercentage,
      geographicExpansion: json['geographicExpansion'] != null
          ? GeographicExpansion.fromJson(json['geographicExpansion'] as Map<String, dynamic>)
          : null,
      leaderExpertise: json['leaderExpertise'] != null
          ? Map<String, Map<String, String>>.from(
              (json['leaderExpertise'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  Map<String, String>.from(value as Map<String, dynamic>),
                ),
              ),
            )
          : {},
    );
  }

  /// Copy with method
  @override
  Club copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? originatingEventId,
    OriginatingEventType? originatingEventType,
    List<String>? memberIds,
    int? memberCount,
    String? founderId,
    List<String>? eventIds,
    int? eventCount,
    double? memberGrowthRate,
    double? eventGrowthRate,
    DateTime? createdAt,
    DateTime? lastEventAt,
    double? engagementScore,
    double? diversityScore,
    ActivityLevel? activityLevel,
    String? originalLocality,
    List<String>? currentLocalities,
    DateTime? updatedAt,
    bool? isClub,
    List<String>? leaders,
    List<String>? adminTeam,
    ClubHierarchy? hierarchy,
    Map<String, ClubRole>? memberRoles,
    List<String>? pendingMembers,
    List<String>? bannedMembers,
    double? organizationalMaturity,
    double? leadershipStability,
    List<String>? expansionLocalities,
    List<String>? expansionCities,
    Map<String, double>? coveragePercentage,
    GeographicExpansion? geographicExpansion,
    Map<String, Map<String, String>>? leaderExpertise,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      originatingEventId: originatingEventId ?? this.originatingEventId,
      originatingEventType: originatingEventType ?? this.originatingEventType,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      founderId: founderId ?? this.founderId,
      eventIds: eventIds ?? this.eventIds,
      eventCount: eventCount ?? this.eventCount,
      memberGrowthRate: memberGrowthRate ?? this.memberGrowthRate,
      eventGrowthRate: eventGrowthRate ?? this.eventGrowthRate,
      createdAt: createdAt ?? this.createdAt,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      engagementScore: engagementScore ?? this.engagementScore,
      diversityScore: diversityScore ?? this.diversityScore,
      activityLevel: activityLevel ?? this.activityLevel,
      originalLocality: originalLocality ?? this.originalLocality,
      currentLocalities: currentLocalities ?? this.currentLocalities,
      updatedAt: updatedAt ?? this.updatedAt,
      leaders: leaders ?? this.leaders,
      adminTeam: adminTeam ?? this.adminTeam,
      hierarchy: hierarchy ?? this.hierarchy,
      memberRoles: memberRoles ?? this.memberRoles,
      pendingMembers: pendingMembers ?? this.pendingMembers,
      bannedMembers: bannedMembers ?? this.bannedMembers,
      organizationalMaturity:
          organizationalMaturity ?? this.organizationalMaturity,
      leadershipStability: leadershipStability ?? this.leadershipStability,
      expansionLocalities: expansionLocalities ?? this.expansionLocalities,
      expansionCities: expansionCities ?? this.expansionCities,
      coveragePercentage: coveragePercentage ?? this.coveragePercentage,
      geographicExpansion: geographicExpansion ?? this.geographicExpansion,
      leaderExpertise: leaderExpertise ?? this.leaderExpertise,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        isClub,
        leaders,
        adminTeam,
        hierarchy,
        memberRoles,
        pendingMembers,
        bannedMembers,
        organizationalMaturity,
        leadershipStability,
        expansionLocalities,
        expansionCities,
        coveragePercentage,
        geographicExpansion,
        leaderExpertise,
      ];
}

