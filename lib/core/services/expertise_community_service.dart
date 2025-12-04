import 'package:spots/core/models/expertise_community.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Community Service
/// Manages expertise-based communities
class ExpertiseCommunityService {
  static const String _logName = 'ExpertiseCommunityService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Create a new expertise community
  Future<ExpertiseCommunity> createCommunity({
    required UnifiedUser creator,
    required String category,
    String? location,
    String? description,
    ExpertiseLevel? minLevel,
    bool isPublic = true,
  }) async {
    try {
      _logger.info('Creating expertise community: $category', tag: _logName);

      // Verify creator has expertise in category
      if (!creator.hasExpertiseIn(category)) {
        throw Exception('Creator must have expertise in $category');
      }

      final community = ExpertiseCommunity(
        id: _generateCommunityId(category, location),
        category: category,
        location: location,
        name: location != null 
            ? '$category Experts of $location'
            : '$category Experts',
        description: description,
        memberIds: [creator.id],
        memberCount: 1,
        minLevel: minLevel,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: creator.id,
      );

      // In production, save to database
      await _saveCommunity(community);

      _logger.info('Created community: ${community.id}', tag: _logName);
      return community;
    } catch (e) {
      _logger.error('Error creating community', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Join a community
  Future<void> joinCommunity(ExpertiseCommunity community, UnifiedUser user) async {
    try {
      _logger.info('User ${user.id} joining community ${community.id}', tag: _logName);

      if (!community.canUserJoin(user)) {
        throw Exception('User cannot join this community');
      }

      if (community.isMember(user)) {
        throw Exception('User is already a member');
      }

      // Add user to community
      final updated = community.copyWith(
        memberIds: [...community.memberIds, user.id],
        memberCount: community.memberCount + 1,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('User joined community', tag: _logName);
    } catch (e) {
      _logger.error('Error joining community', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(ExpertiseCommunity community, UnifiedUser user) async {
    try {
      if (!community.isMember(user)) {
        throw Exception('User is not a member');
      }

      final updated = community.copyWith(
        memberIds: community.memberIds.where((id) => id != user.id).toList(),
        memberCount: community.memberCount - 1,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('User left community', tag: _logName);
    } catch (e) {
      _logger.error('Error leaving community', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Find communities for a user
  Future<List<ExpertiseCommunity>> findCommunitiesForUser(UnifiedUser user) async {
    try {
      final userCategories = user.getExpertiseCategories();
      final allCommunities = await _getAllCommunities();
      
      return allCommunities.where((community) {
        if (!userCategories.contains(community.category)) return false;
        return community.canUserJoin(user);
      }).toList();
    } catch (e) {
      _logger.error('Error finding communities', error: e, tag: _logName);
      return [];
    }
  }

  /// Search communities
  Future<List<ExpertiseCommunity>> searchCommunities({
    String? category,
    String? location,
    int maxResults = 20,
  }) async {
    try {
      final allCommunities = await _getAllCommunities();
      
      return allCommunities.where((community) {
        if (category != null && community.category != category) return false;
        if (location != null) {
          if (community.location == null) return false;
          if (!community.location!.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }
        return true;
      }).take(maxResults).toList();
    } catch (e) {
      _logger.error('Error searching communities', error: e, tag: _logName);
      return [];
    }
  }

  /// Get community members
  Future<List<UnifiedUser>> getCommunityMembers(ExpertiseCommunity community) async {
    try {
      // In production, fetch users by IDs
      return [];
    } catch (e) {
      _logger.error('Error getting community members', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  String _generateCommunityId(String category, String? location) {
    final base = category.toLowerCase().replaceAll(' ', '_');
    final loc = location != null ? '_${location.toLowerCase().replaceAll(' ', '_')}' : '';
    return '${base}${loc}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveCommunity(ExpertiseCommunity community) async {
    // In production, save to database
  }

  Future<List<ExpertiseCommunity>> _getAllCommunities() async {
    // In production, query database
    return [];
  }
}

