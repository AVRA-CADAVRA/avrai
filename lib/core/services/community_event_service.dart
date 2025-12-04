import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/community_service.dart';

/// Community Event Service
/// 
/// Manages non-expert community events (dinner parties, park hangs, walks, runs, etc.)
/// 
/// **Philosophy Alignment:**
/// - Opens doors for anyone to host community events (no expertise gate)
/// - Enables organic community building
/// - Creates natural path from community events to expert events
/// - Tracks event metrics for upgrade eligibility
/// - Auto-creates communities from successful events
/// 
/// **Key Features:**
/// - Non-experts can create events (no expertise required)
/// - No payment on app (price must be null or 0.0, isPaid must be false)
/// - Public events only (isPublic must be true)
/// - Event metrics tracking (attendance, engagement, growth, diversity)
/// - Event management (get, update, cancel)
/// - Integration with ExpertiseEventService (community events appear in search)
/// - Integration with CommunityService (auto-create communities from successful events)
class CommunityEventService {
  static const String _logName = 'CommunityEventService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final CommunityService _communityService;

  CommunityEventService({
    CommunityService? communityService,
  }) : _communityService = communityService ?? CommunityService();

  /// Create a new community event
  /// Allows non-experts to create events (no expertise level required)
  Future<CommunityEvent> createCommunityEvent({
    required UnifiedUser host,
    required String title,
    required String description,
    required String category,
    required ExpertiseEventType eventType,
    required DateTime startTime,
    required DateTime endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    int maxAttendees = 20,
    bool isPublic = true,
  }) async {
    try {
      _logger.info('Creating community event: $title', tag: _logName);

      // Validate community event requirements
      _validateCommunityEventRequirements(
        title: title,
        description: description,
        category: category,
        startTime: startTime,
        endTime: endTime,
        isPublic: isPublic,
      );

      // Get host expertise level (null for non-experts)
      final hostExpertiseLevel = host.hasExpertiseIn(category)
          ? host.getExpertiseLevel(category)
          : null;

      final event = CommunityEvent(
        id: _generateEventId(),
        title: title,
        description: description,
        category: category,
        eventType: eventType,
        host: host,
        startTime: startTime,
        endTime: endTime,
        spots: spots ?? [],
        location: location,
        latitude: latitude,
        longitude: longitude,
        price: null, // Community events cannot charge on app
        isPaid: false, // Community events cannot be paid
        isPublic: isPublic, // Community events must be public
        maxAttendees: maxAttendees,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: EventStatus.upcoming,
        hostExpertiseLevel: hostExpertiseLevel,
      );

      // In production, save to database
      await _saveEvent(event);

      _logger.info('Created community event: ${event.id}', tag: _logName);
      return event;
    } catch (e) {
      _logger.error('Error creating community event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Validate community event requirements
  void _validateCommunityEventRequirements({
    required String title,
    required String description,
    required String category,
    required DateTime startTime,
    required DateTime endTime,
    required bool isPublic,
  }) {
    // Validate title
    if (title.trim().isEmpty) {
      throw Exception('Event title is required');
    }

    // Validate description
    if (description.trim().isEmpty) {
      throw Exception('Event description is required');
    }

    // Validate category
    if (category.trim().isEmpty) {
      throw Exception('Event category is required');
    }

    // Validate dates
    if (startTime.isBefore(DateTime.now())) {
      throw Exception('Event start time must be in the future');
    }

    if (endTime.isBefore(startTime)) {
      throw Exception('Event end time must be after start time');
    }

    // Validate public requirement
    if (!isPublic) {
      throw Exception('Community events must be public (isPublic must be true)');
    }
  }

  /// Track attendance for an event
  Future<void> trackAttendance(
    CommunityEvent event,
    int attendanceCount,
  ) async {
    try {
      _logger.info(
        'Tracking attendance for event ${event.id}: $attendanceCount',
        tag: _logName,
      );

      // Update attendance count
      final updated = event.copyWith(
        attendeeCount: attendanceCount,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Attendance tracked for event', tag: _logName);
    } catch (e) {
      _logger.error('Error tracking attendance', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Track engagement for an event
  /// Updates engagement score based on views, saves, shares
  Future<void> trackEngagement(
    CommunityEvent event, {
    int? viewCount,
    int? saveCount,
    int? shareCount,
  }) async {
    try {
      _logger.info(
        'Tracking engagement for event ${event.id}',
        tag: _logName,
      );

      // Calculate engagement score (0.0 to 1.0)
      final newViewCount = viewCount ?? event.viewCount;
      final newSaveCount = saveCount ?? event.saveCount;
      final newShareCount = shareCount ?? event.shareCount;

      // Normalize engagement metrics
      // Views: max 1000 views = 1.0 (weight: 0.3)
      // Saves: max 100 saves = 1.0 (weight: 0.4)
      // Shares: max 50 shares = 1.0 (weight: 0.3)
      final viewScore = (newViewCount / 1000.0).clamp(0.0, 1.0) * 0.3;
      final saveScore = (newSaveCount / 100.0).clamp(0.0, 1.0) * 0.4;
      final shareScore = (newShareCount / 50.0).clamp(0.0, 1.0) * 0.3;

      final engagementScore = (viewScore + saveScore + shareScore).clamp(0.0, 1.0);

      final updated = event.copyWith(
        viewCount: newViewCount,
        saveCount: newSaveCount,
        shareCount: newShareCount,
        engagementScore: engagementScore,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Engagement tracked for event', tag: _logName);
    } catch (e) {
      _logger.error('Error tracking engagement', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Track growth metrics for an event
  /// Updates growth metrics based on attendance growth over time
  Future<void> trackGrowth(
    CommunityEvent event,
    List<int> attendanceHistory, {
    int? timesHosted,
  }) async {
    try {
      _logger.info(
        'Tracking growth for event ${event.id}',
        tag: _logName,
      );

      // Calculate growth metrics (0.0 to 1.0)
      double growthMetrics = 0.0;

      if (attendanceHistory.length >= 2) {
        // Calculate average growth rate
        double totalGrowth = 0.0;
        int growthCount = 0;

        for (int i = 1; i < attendanceHistory.length; i++) {
          final previous = attendanceHistory[i - 1];
          final current = attendanceHistory[i];

          if (previous > 0) {
            final growthRate = (current - previous) / previous;
            totalGrowth += growthRate;
            growthCount++;
          }
        }

        if (growthCount > 0) {
          final avgGrowth = totalGrowth / growthCount;
          // Normalize: positive growth (up to 100% = 1.0)
          growthMetrics = avgGrowth.clamp(0.0, 1.0);
        }
      }

      final updated = event.copyWith(
        timesHosted: timesHosted ?? event.timesHosted,
        growthMetrics: growthMetrics,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Growth tracked for event', tag: _logName);
    } catch (e) {
      _logger.error('Error tracking growth', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Track diversity metrics for an event
  /// Updates diversity metrics based on attendee diversity (based on AI agents)
  Future<void> trackDiversity(
    CommunityEvent event,
    double diversityScore, {
    List<String>? attendeePersonalityTypes,
  }) async {
    try {
      _logger.info(
        'Tracking diversity for event ${event.id}',
        tag: _logName,
      );

      // Diversity score should be 0.0 to 1.0 (provided by AI analysis)
      final diversityMetrics = diversityScore.clamp(0.0, 1.0);

      final updated = event.copyWith(
        diversityMetrics: diversityMetrics,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Diversity tracked for event', tag: _logName);

      // Check if event is successful and should create a community
      await _checkAndCreateCommunity(updated);
    } catch (e) {
      _logger.error('Error tracking diversity', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check if event is successful and create community
  /// 
  /// Auto-creates a community from a successful event when:
  /// - Event has sufficient attendees
  /// - Event has repeat attendees
  /// - Event has high engagement
  /// - Event is completed
  Future<void> _checkAndCreateCommunity(CommunityEvent event) async {
    try {
      // Only create community for completed events
      if (event.status != EventStatus.completed) {
        return;
      }

      // Check if event meets success criteria
      final minAttendees = 5;
      final minRepeatAttendees = 2;
      final minEngagementScore = 0.6;

      final meetsAttendeeCriteria = event.attendeeCount >= minAttendees;
      final meetsRepeatAttendeeCriteria =
          event.repeatAttendeesCount >= minRepeatAttendees;
      final meetsEngagementCriteria = event.engagementScore >= minEngagementScore;

      if (meetsAttendeeCriteria &&
          meetsRepeatAttendeeCriteria &&
          meetsEngagementCriteria) {
        _logger.info(
          'Event ${event.id} meets success criteria, creating community',
          tag: _logName,
        );

        try {
          await _communityService.createCommunityFromEvent(
            event: event,
            minAttendees: minAttendees,
            minRepeatAttendees: minRepeatAttendees,
            minEngagementScore: minEngagementScore,
            hostWantsCommunity: true,
          );

          _logger.info(
            'Community created from successful event: ${event.id}',
            tag: _logName,
          );
        } catch (e) {
          // Log error but don't fail the diversity tracking
          _logger.warning(
            'Error creating community from event: ${e.toString()}',
            tag: _logName,
          );
        }
      }
    } catch (e) {
      // Log error but don't fail the diversity tracking
      _logger.warning(
        'Error checking community creation: ${e.toString()}',
        tag: _logName,
      );
    }
  }

  /// Get all community events
  Future<List<CommunityEvent>> getCommunityEvents({
    String? category,
    String? location,
    ExpertiseEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int maxResults = 50,
  }) async {
    try {
      final allEvents = await _getAllEvents();

      // Filter events
      final filteredEvents = allEvents.where((event) {
        if (category != null && event.category != category) return false;
        if (location != null && event.location != null) {
          if (!event.location!
              .toLowerCase()
              .contains(location.toLowerCase())) {
            return false;
          }
        }
        if (eventType != null && event.eventType != eventType) return false;
        if (startDate != null && event.startTime.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && event.endTime.isAfter(endDate)) return false;
        if (event.status != EventStatus.upcoming) return false;
        return true;
      }).toList();

      // Sort by start time (earliest first)
      filteredEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      return filteredEvents.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error getting community events', error: e, tag: _logName);
      return [];
    }
  }

  /// Get community events hosted by a specific host
  Future<List<CommunityEvent>> getCommunityEventsByHost(
    UnifiedUser host,
  ) async {
    try {
      final allEvents = await _getAllEvents();
      return allEvents
          .where((event) => event.host.id == host.id)
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _logger.error(
        'Error getting community events by host',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get community events by category
  Future<List<CommunityEvent>> getCommunityEventsByCategory(
    String category, {
    int maxResults = 20,
  }) async {
    return getCommunityEvents(
      category: category,
      maxResults: maxResults,
    );
  }

  /// Update community event details
  Future<CommunityEvent> updateCommunityEvent({
    required CommunityEvent event,
    String? title,
    String? description,
    String? category,
    ExpertiseEventType? eventType,
    DateTime? startTime,
    DateTime? endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    int? maxAttendees,
  }) async {
    try {
      _logger.info('Updating community event: ${event.id}', tag: _logName);

      // Validate updated dates if provided
      if (startTime != null && endTime != null) {
        if (startTime.isBefore(DateTime.now())) {
          throw Exception('Event start time must be in the future');
        }
        if (endTime.isBefore(startTime)) {
          throw Exception('Event end time must be after start time');
        }
      } else if (startTime != null && event.endTime.isBefore(startTime)) {
        throw Exception('Event end time must be after start time');
      } else if (endTime != null && endTime.isBefore(event.startTime)) {
        throw Exception('Event end time must be after start time');
      }

      final updated = event.copyWith(
        title: title,
        description: description,
        category: category,
        eventType: eventType,
        startTime: startTime,
        endTime: endTime,
        spots: spots,
        location: location,
        latitude: latitude,
        longitude: longitude,
        maxAttendees: maxAttendees,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Community event updated', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error('Error updating community event', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Cancel a community event
  Future<CommunityEvent> cancelCommunityEvent(CommunityEvent event) async {
    try {
      _logger.info('Cancelling community event: ${event.id}', tag: _logName);

      final updated = event.copyWith(
        status: EventStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Community event cancelled', tag: _logName);
      return updated;
    } catch (e) {
      _logger.error(
        'Error cancelling community event',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Mark event as completed and check for community creation
  /// 
  /// Marks event as completed and automatically creates a community
  /// if the event meets success criteria.
  Future<CommunityEvent> completeCommunityEvent(CommunityEvent event) async {
    try {
      _logger.info('Completing community event: ${event.id}', tag: _logName);

      final updated = event.copyWith(
        status: EventStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _saveEvent(updated);
      _logger.info('Community event completed', tag: _logName);

      // Check if event is successful and should create a community
      await _checkAndCreateCommunity(updated);

      return updated;
    } catch (e) {
      _logger.error(
        'Error completing community event',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Get community event by ID
  Future<CommunityEvent?> getCommunityEventById(String eventId) async {
    try {
      _logger.info('Getting community event by ID: $eventId', tag: _logName);

      final allEvents = await _getAllEvents();
      try {
        return allEvents.firstWhere((event) => event.id == eventId);
      } catch (e) {
        _logger.info('Community event not found: $eventId', tag: _logName);
        return null;
      }
    } catch (e) {
      _logger.error(
        'Error getting community event by ID: $eventId',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }

  // Private helper methods

  String _generateEventId() {
    return 'community_event_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveEvent(CommunityEvent event) async {
    // In production, save to database
  }

  Future<List<CommunityEvent>> _getAllEvents() async {
    // In production, query database
    return [];
  }
}

