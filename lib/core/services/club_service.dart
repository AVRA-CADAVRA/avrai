import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/club.dart';
import 'package:spots/core/models/club_hierarchy.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/community_service.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';
import 'package:spots/core/services/expansion_expertise_gain_service.dart';

/// Club Service
/// 
/// Manages clubs (communities with organizational structure).
/// 
/// **Philosophy Alignment:**
/// - Communities can organize as clubs when structure is needed
/// - Club leaders gain expertise recognition
/// - Organizational structure enables community growth and geographic expansion
/// 
/// **Key Features:**
/// - Upgrade community to club
/// - Manage club leaders (add, remove, get, check)
/// - Manage admin team (add, remove, get, check)
/// - Manage member roles (assign, get, check permissions)
/// - Club management (get, update)
/// - Integration with CommunityService
class ClubService {
  static const String _logName = 'ClubService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final CommunityService _communityService;

  // In-memory storage (in production, use database)
  final Map<String, Club> _clubs = {};

  ClubService({
    CommunityService? communityService,
  }) : _communityService = communityService ?? CommunityService();

  /// Upgrade community to club
  /// 
  /// Upgrades a community to a club when organizational structure is needed.
  /// 
  /// **Upgrade Criteria:**
  /// - Community has X+ members (default: 10)
  /// - Community has hosted Y+ events (default: 3)
  /// - Community has stable leadership (founder active)
  /// - Community needs organizational structure
  /// 
  /// **What Gets Created:**
  /// - Club extends Community
  /// - Founder becomes initial leader
  /// - Organizational structure (hierarchy) created
  /// - Preserves community history
  Future<Club> upgradeToClub({
    required Community community,
    int minMembers = 10,
    int minEvents = 3,
    bool needsStructure = true,
  }) async {
    try {
      _logger.info(
        'Upgrading community ${community.id} to club',
        tag: _logName,
      );

      // Check upgrade criteria
      if (community.memberCount < minMembers) {
        throw Exception(
          'Community must have at least $minMembers members to upgrade to club',
        );
      }

      if (community.eventCount < minEvents) {
        throw Exception(
          'Community must have hosted at least $minEvents events to upgrade to club',
        );
      }

      if (!needsStructure) {
        throw Exception('Community must need organizational structure to upgrade');
      }

      // Create club from community
      final club = Club.fromCommunity(
        community: community,
        leaders: [community.founderId], // Founder becomes initial leader
        adminTeam: [],
        hierarchy: ClubHierarchy(),
        memberRoles: {}, // All members start as regular members
        pendingMembers: [],
        bannedMembers: [],
        organizationalMaturity: 0.5, // Starting maturity
        leadershipStability: 0.7, // Founder is stable
        expansionLocalities: [],
        expansionCities: [],
        coveragePercentage: {},
      );

      // Save club
      await _saveClub(club);

      _logger.info('Upgraded community to club: ${club.id}', tag: _logName);
      return club;
    } catch (e) {
      _logger.error('Error upgrading community to club', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Add leader to club
  Future<void> addLeader(Club club, String userId) async {
    try {
      _logger.info('Adding leader $userId to club ${club.id}', tag: _logName);

      if (club.leaders.contains(userId)) {
        _logger.warning(
          'User $userId is already a leader of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // User must be a member
      if (!club.isMember(userId)) {
        throw Exception('User must be a member to become a leader');
      }

      // Remove from admin team if present
      List<String> updatedAdminTeam = club.adminTeam;
      if (updatedAdminTeam.contains(userId)) {
        updatedAdminTeam = updatedAdminTeam.where((id) => id != userId).toList();
      }

      // Remove from member roles if present
      Map<String, ClubRole> updatedMemberRoles = Map.from(club.memberRoles);
      updatedMemberRoles.remove(userId);

      final updated = club.copyWith(
        leaders: [...club.leaders, userId],
        adminTeam: updatedAdminTeam,
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Added leader to club', tag: _logName);
    } catch (e) {
      _logger.error('Error adding leader', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove leader from club
  Future<void> removeLeader(Club club, String userId) async {
    try {
      _logger.info('Removing leader $userId from club ${club.id}', tag: _logName);

      if (!club.leaders.contains(userId)) {
        _logger.warning(
          'User $userId is not a leader of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // Cannot remove founder if they're the only leader
      if (club.founderId == userId && club.leaders.length == 1) {
        throw Exception('Cannot remove founder if they are the only leader');
      }

      final updated = club.copyWith(
        leaders: club.leaders.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Removed leader from club', tag: _logName);
    } catch (e) {
      _logger.error('Error removing leader', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all leaders
  List<String> getLeaders(Club club) {
    return club.leaders;
  }

  /// Check if user is a leader
  bool isLeader(Club club, String userId) {
    return club.isLeader(userId);
  }

  /// Add admin to club
  Future<void> addAdmin(Club club, String userId) async {
    try {
      _logger.info('Adding admin $userId to club ${club.id}', tag: _logName);

      if (club.adminTeam.contains(userId)) {
        _logger.warning(
          'User $userId is already an admin of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      // User must be a member
      if (!club.isMember(userId)) {
        throw Exception('User must be a member to become an admin');
      }

      // Cannot add if already a leader
      if (club.isLeader(userId)) {
        throw Exception('User is already a leader');
      }

      // Remove from member roles if present
      Map<String, ClubRole> updatedMemberRoles = Map.from(club.memberRoles);
      updatedMemberRoles.remove(userId);

      final updated = club.copyWith(
        adminTeam: [...club.adminTeam, userId],
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Added admin to club', tag: _logName);
    } catch (e) {
      _logger.error('Error adding admin', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove admin from club
  Future<void> removeAdmin(Club club, String userId) async {
    try {
      _logger.info('Removing admin $userId from club ${club.id}', tag: _logName);

      if (!club.adminTeam.contains(userId)) {
        _logger.warning(
          'User $userId is not an admin of club ${club.id}',
          tag: _logName,
        );
        return;
      }

      final updated = club.copyWith(
        adminTeam: club.adminTeam.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Removed admin from club', tag: _logName);
    } catch (e) {
      _logger.error('Error removing admin', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all admins
  List<String> getAdmins(Club club) {
    return club.adminTeam;
  }

  /// Check if user is an admin
  bool isAdmin(Club club, String userId) {
    return club.isAdmin(userId);
  }

  /// Assign role to member
  Future<void> assignRole(
    Club club,
    String userId,
    ClubRole role,
  ) async {
    try {
      _logger.info(
        'Assigning role ${role.name} to user $userId in club ${club.id}',
        tag: _logName,
      );

      // User must be a member
      if (!club.isMember(userId)) {
        throw Exception('User must be a member to assign a role');
      }

      // Cannot assign leader or admin role (use addLeader/addAdmin)
      if (role == ClubRole.leader) {
        throw Exception('Use addLeader() to assign leader role');
      }
      if (role == ClubRole.admin) {
        throw Exception('Use addAdmin() to assign admin role');
      }

      // Remove from leaders/admins if present
      List<String> updatedLeaders = club.leaders;
      List<String> updatedAdminTeam = club.adminTeam;
      if (updatedLeaders.contains(userId)) {
        updatedLeaders = updatedLeaders.where((id) => id != userId).toList();
      }
      if (updatedAdminTeam.contains(userId)) {
        updatedAdminTeam = updatedAdminTeam.where((id) => id != userId).toList();
      }

      // Update member roles
      Map<String, ClubRole> updatedMemberRoles = Map.from(club.memberRoles);
      if (role == ClubRole.member) {
        updatedMemberRoles.remove(userId); // Default role, no need to store
      } else {
        updatedMemberRoles[userId] = role;
      }

      final updated = club.copyWith(
        leaders: updatedLeaders,
        adminTeam: updatedAdminTeam,
        memberRoles: updatedMemberRoles,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Assigned role to member', tag: _logName);
    } catch (e) {
      _logger.error('Error assigning role', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get member's role
  ClubRole? getMemberRole(Club club, String userId) {
    return club.getMemberRole(userId);
  }

  /// Check if member has permission
  bool hasPermission(Club club, String userId, String permission) {
    return club.hasPermission(userId, permission);
  }

  /// Get club by ID
  Future<Club?> getClubById(String clubId) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs.firstWhere(
        (c) => c.id == clubId,
        orElse: () => throw Exception('Club not found'),
      );
    } catch (e) {
      _logger.error('Error getting club by ID', error: e, tag: _logName);
      return null;
    }
  }

  /// Get clubs by leader
  Future<List<Club>> getClubsByLeader(String leaderId) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs
          .where((c) => c.isLeader(leaderId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error('Error getting clubs by leader', error: e, tag: _logName);
      return [];
    }
  }

  /// Get clubs by category
  Future<List<Club>> getClubsByCategory(
    String category, {
    int maxResults = 20,
  }) async {
    try {
      final allClubs = await _getAllClubs();
      return allClubs
          .where((c) => c.category == category)
          .take(maxResults)
          .toList()
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } catch (e) {
      _logger.error('Error getting clubs by category', error: e, tag: _logName);
      return [];
    }
  }

  /// Update club details
  Future<Club> updateClub({
    required Club club,
    String? name,
    String? description,
    List<String>? currentLocalities,
    List<String>? expansionLocalities,
    List<String>? expansionCities,
    Map<String, double>? coveragePercentage,
    double? organizationalMaturity,
    double? leadershipStability,
  }) async {
    try {
      _logger.info('Updating club: ${club.id}', tag: _logName);

      final updated = club.copyWith(
        name: name,
        description: description,
        currentLocalities: currentLocalities,
        expansionLocalities: expansionLocalities,
        expansionCities: expansionCities,
        coveragePercentage: coveragePercentage,
        organizationalMaturity: organizationalMaturity,
        leadershipStability: leadershipStability,
        updatedAt: DateTime.now(),
      );

      await _saveClub(updated);
      _logger.info('Updated club', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating club', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Grant expertise to club leaders
  /// 
  /// Grants expertise to club leaders in all localities where club hosts events.
  /// 
  /// **Philosophy Alignment:**
  /// - Club leaders recognized as experts (doors for leaders)
  /// - Leaders gain expertise in all localities where club hosts events
  /// 
  /// **Parameters:**
  /// - `club`: Club
  /// - `category`: Category for expertise
  /// - `expansionExpertiseGainService`: Service to grant expertise from expansion
  /// 
  /// **Returns:**
  /// Map of leader ID → updated user (with new expertise)
  Future<Map<String, UnifiedUser>> grantLeaderExpertise({
    required Club club,
    required String category,
    required ExpansionExpertiseGainService expansionExpertiseGainService,
  }) async {
    try {
      _logger.info(
        'Granting leader expertise: club=${club.id}, category=$category, leaders=${club.leaders.length}',
        tag: _logName,
      );

      final updatedLeaders = <String, UnifiedUser>{};

      // Get expansion for club
      final expansionService = GeographicExpansionService();
      final expansion = expansionService.getExpansionByClub(club.id);

      if (expansion == null) {
        _logger.warning(
          'No expansion found for club ${club.id}',
          tag: _logName,
        );
        return updatedLeaders;
      }

      // Grant expertise to each leader
      for (final leaderId in club.leaders) {
        // In production, would fetch user from database
        // For now, create a placeholder user (this would be replaced with actual user fetch)
        // TODO: Replace with actual user fetch from user service
        final leader = UnifiedUser(
          id: leaderId,
          email: '$leaderId@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Grant expertise from expansion
        final updatedLeader = await expansionExpertiseGainService.grantExpertiseFromExpansion(
          user: leader,
          expansion: expansion,
          category: category,
        );

        updatedLeaders[leaderId] = updatedLeader;
      }

      _logger.info(
        'Granted leader expertise: club=${club.id}, leaders=${updatedLeaders.length}',
        tag: _logName,
      );

      return updatedLeaders;
    } catch (e) {
      _logger.error('Error granting leader expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update leader expertise when club expands
  /// 
  /// Called when club expands to new localities.
  /// 
  /// **Parameters:**
  /// - `club`: Club
  /// - `category`: Category for expertise
  /// - `expansionExpertiseGainService`: Service to grant expertise from expansion
  /// 
  /// **Returns:**
  /// Updated club with leader expertise tracked
  Future<Club> updateLeaderExpertise({
    required Club club,
    required String category,
    required ExpansionExpertiseGainService expansionExpertiseGainService,
  }) async {
    try {
      _logger.info(
        'Updating leader expertise: club=${club.id}, category=$category',
        tag: _logName,
      );

      // Grant expertise to leaders
      final updatedLeaders = await grantLeaderExpertise(
        club: club,
        category: category,
        expansionExpertiseGainService: expansionExpertiseGainService,
      );

      // Update club with leader expertise (stored in leaderExpertise map)
      // Note: This would require updating Club model to include leaderExpertise field
      // For now, just log the update
      _logger.info(
        'Updated leader expertise: club=${club.id}, leaders=${updatedLeaders.length}',
        tag: _logName,
      );

      return club;
    } catch (e) {
      _logger.error('Error updating leader expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get expertise for a club leader
  /// 
  /// **Parameters:**
  /// - `club`: Club
  /// - `leaderId`: Leader user ID
  /// - `category`: Category for expertise
  /// 
  /// **Returns:**
  /// Expertise level for leader in category, or null if not found
  ExpertiseLevel? getLeaderExpertise({
    required Club club,
    required String leaderId,
    required String category,
  }) {
    try {
      // Check if user is a leader
      if (!club.isLeader(leaderId)) {
        return null;
      }

      // In production, would fetch user from database and get expertise
      // For now, return null (would be replaced with actual user fetch)
      // TODO: Replace with actual user fetch from user service
      return null;
    } catch (e) {
      _logger.error('Error getting leader expertise', error: e, tag: _logName);
      return null;
    }
  }

  // Private helper methods

  Future<void> _saveClub(Club club) async {
    // In production, save to database
    _clubs[club.id] = club;
  }

  Future<List<Club>> _getAllClubs() async {
    // In production, query database
    return _clubs.values.toList();
  }
}

