import 'package:spots/core/models/community.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/geographic_expansion.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';

/// Community Service
/// 
/// Manages communities that form from events (people who attend together).
/// 
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities form organically from successful events
/// - People find their communities through events
/// - Communities can organize as clubs when structure is needed
/// 
/// **Key Features:**
/// - Auto-create community from successful events
/// - Manage community members (add, remove, get, check membership)
/// - Manage community events (add, get, get upcoming)
/// - Track community growth (member growth, event growth)
/// - Calculate community metrics (engagement, diversity)
/// - Community management (get, update, delete)
class CommunityService {
  static const String _logName = 'CommunityService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // In-memory storage (in production, use database)
  final Map<String, Community> _communities = {};

  final GeographicExpansionService _expansionService;

  CommunityService({
    GeographicExpansionService? expansionService,
  }) : _expansionService =
            expansionService ?? GeographicExpansionService();

  /// Auto-create community from successful event
  /// 
  /// Creates a community when an event is successful (meets success criteria).
  /// 
  /// **Success Criteria:**
  /// - Event had X+ attendees (default: 5)
  /// - Event had Y+ repeat attendees (default: 2)
  /// - Event had high engagement (engagement score >= 0.6)
  /// - Event host wants to create community (optional)
  /// 
  /// **What Gets Created:**
  /// - Community linked to originating event
  /// - Event host becomes founder
  /// - Event attendees become initial members
  /// - Community name based on event title/category
  Future<Community> createCommunityFromEvent({
    required ExpertiseEvent event,
    int minAttendees = 5,
    int minRepeatAttendees = 2,
    double minEngagementScore = 0.6,
    bool hostWantsCommunity = true,
  }) async {
    try {
      _logger.info(
        'Creating community from event: ${event.id}',
        tag: _logName,
      );

      // Determine event type
      OriginatingEventType eventType;
      if (event is CommunityEvent) {
        eventType = OriginatingEventType.communityEvent;
      } else {
        eventType = OriginatingEventType.expertiseEvent;
      }

      // Check success criteria
      final meetsAttendeeCriteria = event.attendeeCount >= minAttendees;
      
      // For CommunityEvent, check repeat attendees and engagement
      int repeatAttendees = 0;
      double engagementScore = 0.0;
      if (event is CommunityEvent) {
        repeatAttendees = event.repeatAttendeesCount;
        engagementScore = event.engagementScore;
      }

      final meetsRepeatAttendeeCriteria = repeatAttendees >= minRepeatAttendees;
      final meetsEngagementCriteria = engagementScore >= minEngagementScore;

      // Check if event meets success criteria
      if (!meetsAttendeeCriteria) {
        throw Exception(
          'Event must have at least $minAttendees attendees to create community',
        );
      }

      // For CommunityEvent, also check repeat attendees and engagement
      if (event is CommunityEvent) {
        if (!meetsRepeatAttendeeCriteria) {
          throw Exception(
            'Event must have at least $minRepeatAttendees repeat attendees to create community',
          );
        }
        if (!meetsEngagementCriteria) {
          throw Exception(
            'Event must have engagement score >= $minEngagementScore to create community',
          );
        }
      }

      // Extract locality from event location
      String originalLocality = 'Unknown';
      if (event.location != null && event.location!.isNotEmpty) {
        // Location format: "Locality, City, State, Country" or "Locality, City"
        final parts = event.location!.split(',');
        originalLocality = parts.first.trim();
      }

      // Create community name from event
      final communityName = '${event.category} Community - ${event.title}';

      // Create community
      final community = Community(
        id: _generateCommunityId(),
        name: communityName,
        description: 'Community formed from event: ${event.title}',
        category: event.category,
        originatingEventId: event.id,
        originatingEventType: eventType,
        memberIds: [event.host.id, ...event.attendeeIds],
        memberCount: event.attendeeCount + 1, // +1 for host
        founderId: event.host.id,
        eventIds: [event.id],
        eventCount: 1,
        memberGrowthRate: 0.0,
        eventGrowthRate: 0.0,
        createdAt: DateTime.now(),
        lastEventAt: event.startTime,
        engagementScore: event is CommunityEvent ? event.engagementScore : 0.0,
        diversityScore: event is CommunityEvent ? event.diversityMetrics : 0.0,
        activityLevel: ActivityLevel.active,
        originalLocality: originalLocality,
        currentLocalities: [originalLocality],
        updatedAt: DateTime.now(),
      );

      // Save community
      await _saveCommunity(community);

      _logger.info('Created community: ${community.id}', tag: _logName);
      return community;
    } catch (e) {
      _logger.error('Error creating community from event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Add member to community
  Future<void> addMember(Community community, String userId) async {
    try {
      _logger.info(
        'Adding member $userId to community ${community.id}',
        tag: _logName,
      );

      if (community.memberIds.contains(userId)) {
        _logger.warning(
          'User $userId is already a member of community ${community.id}',
          tag: _logName,
        );
        return;
      }

      final updated = community.copyWith(
        memberIds: [...community.memberIds, userId],
        memberCount: community.memberCount + 1,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('Added member to community', tag: _logName);
    } catch (e) {
      _logger.error('Error adding member', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Remove member from community
  Future<void> removeMember(Community community, String userId) async {
    try {
      _logger.info(
        'Removing member $userId from community ${community.id}',
        tag: _logName,
      );

      if (!community.memberIds.contains(userId)) {
        _logger.warning(
          'User $userId is not a member of community ${community.id}',
          tag: _logName,
        );
        return;
      }

      // Cannot remove founder
      if (community.founderId == userId) {
        throw Exception('Cannot remove founder from community');
      }

      final updated = community.copyWith(
        memberIds: community.memberIds.where((id) => id != userId).toList(),
        memberCount: community.memberCount - 1,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('Removed member from community', tag: _logName);
    } catch (e) {
      _logger.error('Error removing member', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all members of a community
  List<String> getMembers(Community community) {
    return community.memberIds;
  }

  /// Check if user is a member
  bool isMember(Community community, String userId) {
    return community.isMember(userId);
  }

  /// Add event to community
  Future<void> addEvent(Community community, String eventId) async {
    try {
      _logger.info(
        'Adding event $eventId to community ${community.id}',
        tag: _logName,
      );

      if (community.eventIds.contains(eventId)) {
        _logger.warning(
          'Event $eventId is already in community ${community.id}',
          tag: _logName,
        );
        return;
      }

      final updated = community.copyWith(
        eventIds: [...community.eventIds, eventId],
        eventCount: community.eventCount + 1,
        lastEventAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('Added event to community', tag: _logName);
    } catch (e) {
      _logger.error('Error adding event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get all events hosted by community
  List<String> getEvents(Community community) {
    return community.eventIds;
  }

  /// Get upcoming events (requires event service to filter by date)
  /// This is a placeholder - actual implementation would filter by event dates
  List<String> getUpcomingEvents(Community community) {
    // In production, would filter by event dates using event service
    return community.eventIds;
  }

  /// Update growth metrics
  Future<void> updateGrowthMetrics(
    Community community, {
    double? memberGrowthRate,
    double? eventGrowthRate,
  }) async {
    try {
      _logger.info(
        'Updating growth metrics for community ${community.id}',
        tag: _logName,
      );

      final updated = community.copyWith(
        memberGrowthRate: memberGrowthRate ?? community.memberGrowthRate,
        eventGrowthRate: eventGrowthRate ?? community.eventGrowthRate,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('Updated growth metrics', tag: _logName);
    } catch (e) {
      _logger.error('Error updating growth metrics', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate engagement score
  /// 
  /// Engagement score is based on:
  /// - Member activity (attendance, participation)
  /// - Event frequency
  /// - Member retention
  double calculateEngagementScore(Community community) {
    double score = 0.0;

    // Member activity (40%)
    // Based on member count and growth
    final memberActivity = (community.memberCount / 50.0).clamp(0.0, 1.0);
    score += memberActivity * 0.4;

    // Event frequency (30%)
    // Based on event count and recency
    final eventFrequency = (community.eventCount / 10.0).clamp(0.0, 1.0);
    score += eventFrequency * 0.3;

    // Member retention (30%)
    // Based on member growth rate
    score += community.memberGrowthRate * 0.3;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate diversity score
  /// 
  /// Diversity score is based on:
  /// - Member diversity (from event diversity metrics)
  /// - Geographic diversity (multiple localities)
  double calculateDiversityScore(Community community) {
    double score = 0.0;

    // Member diversity (60%)
    // Use existing diversity score from community
    score += community.diversityScore * 0.6;

    // Geographic diversity (40%)
    // Based on number of localities
    final localityCount = community.currentLocalities.length;
    final geographicDiversity = (localityCount / 5.0).clamp(0.0, 1.0);
    score += geographicDiversity * 0.4;

    return score.clamp(0.0, 1.0);
  }

  /// Get community by ID
  Future<Community?> getCommunityById(String communityId) async {
    try {
      final allCommunities = await _getAllCommunities();
      return allCommunities.firstWhere(
        (c) => c.id == communityId,
        orElse: () => throw Exception('Community not found'),
      );
    } catch (e) {
      _logger.error('Error getting community by ID', error: e, tag: _logName);
      return null;
    }
  }

  /// Get communities by founder
  Future<List<Community>> getCommunitiesByFounder(String founderId) async {
    try {
      final allCommunities = await _getAllCommunities();
      return allCommunities
          .where((c) => c.founderId == founderId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _logger.error(
        'Error getting communities by founder',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get communities by category
  Future<List<Community>> getCommunitiesByCategory(
    String category, {
    int maxResults = 20,
  }) async {
    try {
      final allCommunities = await _getAllCommunities();
      return allCommunities
          .where((c) => c.category == category)
          .take(maxResults)
          .toList()
        ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } catch (e) {
      _logger.error(
        'Error getting communities by category',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Update community details
  Future<Community> updateCommunity({
    required Community community,
    String? name,
    String? description,
    List<String>? currentLocalities,
  }) async {
    try {
      _logger.info('Updating community: ${community.id}', tag: _logName);

      final updated = community.copyWith(
        name: name,
        description: description,
        currentLocalities: currentLocalities,
        updatedAt: DateTime.now(),
      );

      await _saveCommunity(updated);
      _logger.info('Updated community', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating community', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Delete community (only if empty)
  Future<void> deleteCommunity(Community community) async {
    try {
      _logger.info('Deleting community: ${community.id}', tag: _logName);

      // Only allow deletion if community is empty
      if (community.memberCount > 0) {
        throw Exception('Cannot delete community with members');
      }

      if (community.eventCount > 0) {
        throw Exception('Cannot delete community with events');
      }

      await _deleteCommunity(community.id);
      _logger.info('Deleted community', tag: _logName);
    } catch (e) {
      _logger.error('Error deleting community', error: e, tag: _logName);
      rethrow;
    }
  }

  // Private helper methods

  String _generateCommunityId() {
    return 'community_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveCommunity(Community community) async {
    // In production, save to database
    _communities[community.id] = community;
  }

  Future<void> _deleteCommunity(String communityId) async {
    // In production, delete from database
    _communities.remove(communityId);
  }

  Future<List<Community>> _getAllCommunities() async {
    // In production, query database
    return _communities.values.toList();
  }

  /// Track expansion when community hosts events in new localities
  /// 
  /// Called when a community hosts an event in a new locality.
  /// 
  /// **Philosophy Alignment:**
  /// - Communities can expand naturally (doors open through growth)
  /// - Geographic expansion enabled (locality → universe)
  /// 
  /// **Parameters:**
  /// - `community`: Community
  /// - `event`: Event that triggered expansion
  /// - `eventLocation`: Location of the event (locality, city, state, nation)
  /// 
  /// **Returns:**
  /// Updated GeographicExpansion
  Future<GeographicExpansion> trackExpansion({
    required Community community,
    required ExpertiseEvent event,
    required String eventLocation,
  }) async {
    try {
      _logger.info(
        'Tracking expansion: community=${community.id}, event=${event.id}, location=$eventLocation',
        tag: _logName,
      );

      // Track event expansion
      final expansion = await _expansionService.trackEventExpansion(
        clubId: community.id,
        isClub: false, // This is a community, not a club
        event: event,
        eventLocation: eventLocation,
      );

      // Update community's current localities if new locality
      final locality = _extractLocality(eventLocation);
      if (locality != null && !community.currentLocalities.contains(locality)) {
        final updatedCommunity = community.copyWith(
          currentLocalities: [...community.currentLocalities, locality],
          updatedAt: DateTime.now(),
        );
        await _saveCommunity(updatedCommunity);
      }

      _logger.info(
        'Expansion tracked: community=${community.id}, localities=${expansion.expandedLocalities.length}',
        tag: _logName,
      );

      return expansion;
    } catch (e) {
      _logger.error('Error tracking expansion', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Update expansion history
  /// 
  /// Updates expansion history when community expands.
  /// 
  /// **Parameters:**
  /// - `community`: Community
  /// - `expansion`: Updated expansion
  /// 
  /// **Returns:**
  /// Updated expansion
  Future<GeographicExpansion> updateExpansionHistory({
    required Community community,
    required GeographicExpansion expansion,
  }) async {
    try {
      _logger.info(
        'Updating expansion history: community=${community.id}',
        tag: _logName,
      );

      final updatedExpansion = await _expansionService.updateExpansion(expansion);

      _logger.info(
        'Expansion history updated: community=${community.id}',
        tag: _logName,
      );

      return updatedExpansion;
    } catch (e) {
      _logger.error('Error updating expansion history', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }
}

