import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/geographic_scope_service.dart';

/// Event Matching Service
/// 
/// Calculates matching signals (not formal ranking) to help users find likeminded people
/// and events they'll enjoy. This is a matching system, not a competitive ranking.
/// 
/// **Philosophy:** "Doors, not badges" - Opens doors to likeminded people and events
/// 
/// **Matching Signals:**
/// - Events hosted count (more events = higher signal)
/// - Event ratings (average rating from attendees)
/// - Followers count (users following the expert)
/// - External social following (if available)
/// - Community recognition (partnerships, collaborations)
/// - Event growth (community building - attendance growth over time)
/// - Active list respects (users adding events to their lists)
/// 
/// **Locality-Specific Weighting:**
/// - Higher weight for signals in user's locality
/// - Lower weight for signals outside locality
/// - Geographic interaction patterns (where user attends events)
/// 
/// **What Doors Does This Open?**
/// - Discovery Doors: Users find events from likeminded local experts
/// - Connection Doors: System matches users to events they'll enjoy
/// - Exploration Doors: Users can explore events outside their typical behavior
class EventMatchingService {
  static const String _logName = 'EventMatchingService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;
  final GeographicScopeService _geographicScopeService;

  EventMatchingService({
    ExpertiseEventService? eventService,
    GeographicScopeService? geographicScopeService,
  })  : _eventService = eventService ?? ExpertiseEventService(),
        _geographicScopeService =
            geographicScopeService ?? GeographicScopeService();

  /// Calculate matching score for an expert hosting events
  /// 
  /// **Parameters:**
  /// - `expert`: Expert user to calculate score for
  /// - `user`: User looking for events (for locality-specific weighting)
  /// - `category`: Expertise category
  /// - `locality`: Target locality for matching
  /// 
  /// **Returns:**
  /// Matching score (0.0 to 1.0) - higher means better match
  /// 
  /// **Philosophy:**
  /// This is NOT a competitive ranking. It's a matching signal to help users
  /// find likeminded people and events they'll enjoy.
  Future<double> calculateMatchingScore({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    try {
      _logger.info(
        'Calculating matching score: expert=${expert.id}, user=${user.id}, category=$category, locality=$locality',
        tag: _logName,
      );

      // Get matching signals
      final signals = await getMatchingSignals(
        expert: expert,
        user: user,
        category: category,
        locality: locality,
      );

      // Calculate weighted score based on locality-specific weighting
      double score = 0.0;

      // Events hosted (30% weight)
      score += signals.eventsHostedScore * 0.3;

      // Event ratings (25% weight)
      score += signals.averageRating * 0.25;

      // Followers count (15% weight)
      score += signals.followersScore * 0.15;

      // External social following (5% weight - if available)
      score += signals.externalSocialScore * 0.05;

      // Community recognition (10% weight)
      score += signals.communityRecognitionScore * 0.1;

      // Event growth (10% weight - community building)
      score += signals.eventGrowthScore * 0.1;

      // Active list respects (5% weight)
      score += signals.activeListRespectsScore * 0.05;

      return score.clamp(0.0, 1.0);
    } catch (e) {
      _logger.error('Error calculating matching score', error: e, tag: _logName);
      return 0.0;
    }
  }

  /// Get detailed matching signals breakdown
  /// 
  /// **Returns:**
  /// MatchingSignals object with all signal components
  /// Useful for debugging and UI display
  Future<MatchingSignals> getMatchingSignals({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) async {
    try {
      // Get events hosted by expert
      final events = await _eventService.getEventsByHost(expert);
      final categoryEvents = events.where((e) => e.category == category).toList();

      // Calculate locality-specific weighting
      final localityWeight = _calculateLocalityWeight(
        expert: expert,
        user: user,
        locality: locality,
        events: categoryEvents,
      );

      // Events hosted count (more events = higher signal)
      final eventsHostedCount = categoryEvents.length;
      final eventsHostedScore = _normalizeEventsHosted(eventsHostedCount) * localityWeight;

      // Event ratings (average rating from attendees)
      final averageRating = await _calculateAverageRating(categoryEvents);
      final ratingScore = (averageRating / 5.0) * localityWeight; // Normalize to 0-1

      // Followers count (users following the expert)
      final followersCount = expert.friends.length; // Using friends as proxy for followers
      final followersScore = _normalizeFollowers(followersCount) * localityWeight;

      // External social following (if available)
      final externalSocialScore = _getExternalSocialScore(expert) * localityWeight;

      // Community recognition (partnerships, collaborations)
      final communityRecognitionScore = await _calculateCommunityRecognition(
        expert: expert,
        category: category,
        locality: locality,
      ) * localityWeight;

      // Event growth (community building - attendance growth over time)
      final eventGrowthScore = _calculateEventGrowth(categoryEvents) * localityWeight;

      // Active list respects (users adding events to their lists)
      final activeListRespectsScore = await _calculateActiveListRespects(
        expert: expert,
        category: category,
      ) * localityWeight;

      return MatchingSignals(
        eventsHostedCount: eventsHostedCount,
        eventsHostedScore: eventsHostedScore,
        averageRating: averageRating,
        followersCount: followersCount,
        followersScore: followersScore,
        externalSocialScore: externalSocialScore,
        communityRecognitionScore: communityRecognitionScore,
        eventGrowthScore: eventGrowthScore,
        activeListRespectsScore: activeListRespectsScore,
        localityWeight: localityWeight,
      );
    } catch (e) {
      _logger.error('Error getting matching signals', error: e, tag: _logName);
      return MatchingSignals.empty();
    }
  }

  /// Calculate locality-specific weighting
  /// 
  /// **Rules:**
  /// - Higher weight (1.0) for signals in user's locality
  /// - Lower weight (0.5-0.7) for signals outside locality
  /// - Considers geographic interaction patterns (where user attends events)
  /// 
  /// **Returns:**
  /// Weight multiplier (0.0 to 1.0)
  double _calculateLocalityWeight({
    required UnifiedUser expert,
    required UnifiedUser user,
    required String locality,
    required List<ExpertiseEvent> events,
  }) {
    // Extract user's locality from location string
    final userLocality = _extractLocality(user.location);
    final expertLocality = _extractLocality(expert.location);

    // If expert is in same locality as target locality, full weight
    if (expertLocality != null &&
        expertLocality.toLowerCase() == locality.toLowerCase()) {
      return 1.0;
    }

    // If user's locality matches target locality, higher weight for expert in same locality
    if (userLocality != null &&
        userLocality.toLowerCase() == locality.toLowerCase() &&
        expertLocality != null &&
        expertLocality.toLowerCase() == locality.toLowerCase()) {
      return 1.0;
    }

    // Check if user has attended events in this locality (geographic interaction patterns)
    final userAttendedInLocality = events.any((e) {
      final eventLocality = _extractLocality(e.location);
      return eventLocality != null &&
          eventLocality.toLowerCase() == locality.toLowerCase();
    });

    if (userAttendedInLocality) {
      return 0.8; // Higher weight if user has attended events in this locality
    }

    // Default: lower weight for signals outside locality
    return 0.6;
  }

  /// Extract locality from location string
  /// Location format: "Locality, City, State, Country" or "Locality, City"
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Normalize events hosted count to 0-1 scale
  /// More events = higher score (logarithmic scale)
  double _normalizeEventsHosted(int count) {
    if (count == 0) return 0.0;
    // Logarithmic scale: 1 event = 0.3, 5 events = 0.7, 10+ events = 1.0
    return (1.0 - (1.0 / (1.0 + count * 0.2))).clamp(0.0, 1.0);
  }

  /// Calculate average rating from event feedback
  /// 
  /// **Note:** In production, this would query event feedback service
  /// For now, returns a placeholder based on event attendance
  Future<double> _calculateAverageRating(List<ExpertiseEvent> events) async {
    if (events.isEmpty) return 0.0;

    // Placeholder: Use attendance as proxy for rating
    // In production, query PostEventFeedbackService for actual ratings
    double totalRating = 0.0;
    int ratedEvents = 0;

    for (final event in events) {
      // Events with more attendees likely have better ratings
      // Placeholder logic: assume 4.0 base + attendance boost
      if (event.attendeeCount > 0) {
        final attendanceBoost = (event.attendeeCount / event.maxAttendees).clamp(0.0, 1.0) * 0.5;
        totalRating += 4.0 + attendanceBoost;
        ratedEvents++;
      }
    }

    return ratedEvents > 0 ? totalRating / ratedEvents : 0.0;
  }

  /// Normalize followers count to 0-1 scale
  /// More followers = higher score (logarithmic scale)
  double _normalizeFollowers(int count) {
    if (count == 0) return 0.0;
    // Logarithmic scale: 10 followers = 0.3, 50 followers = 0.7, 100+ followers = 1.0
    return (1.0 - (1.0 / (1.0 + count * 0.05))).clamp(0.0, 1.0);
  }

  /// Get external social following score
  /// 
  /// **Note:** In production, this would query external social media APIs
  /// For now, returns placeholder
  double _getExternalSocialScore(UnifiedUser expert) {
    // Placeholder: Return moderate score
    // In production, integrate with social media APIs (Instagram, TikTok, etc.)
    return 0.5;
  }

  /// Calculate community recognition score
  /// 
  /// **Note:** In production, this would query partnerships, collaborations, etc.
  /// For now, returns placeholder based on expertise level
  Future<double> _calculateCommunityRecognition({
    required UnifiedUser expert,
    required String category,
    required String locality,
  }) async {
    // Placeholder: Use expertise level as proxy for community recognition
    final level = expert.getExpertiseLevel(category);
    if (level == null) return 0.0;

    // Higher expertise levels = more community recognition
    return (level.index + 1) / ExpertiseLevel.values.length;
  }

  /// Calculate event growth score
  /// 
  /// Measures community building - attendance growth over time
  /// Events that grow in size show community value
  double _calculateEventGrowth(List<ExpertiseEvent> events) {
    if (events.length < 2) return 0.5; // Need at least 2 events to measure growth

    // Sort events by start time
    final sortedEvents = List<ExpertiseEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Calculate growth trend
    double growthSum = 0.0;
    int growthCount = 0;

    for (int i = 1; i < sortedEvents.length; i++) {
      final previous = sortedEvents[i - 1];
      final current = sortedEvents[i];

      if (previous.attendeeCount > 0) {
        final growth = (current.attendeeCount - previous.attendeeCount) /
            previous.attendeeCount;
        growthSum += growth;
        growthCount++;
      }
    }

    if (growthCount == 0) return 0.5;

    final averageGrowth = growthSum / growthCount;
    // Normalize: positive growth = higher score, negative growth = lower score
    return (0.5 + (averageGrowth * 0.5)).clamp(0.0, 1.0);
  }

  /// Calculate active list respects score
  /// 
  /// **Note:** In production, this would query user_respects table
  /// For now, returns placeholder
  Future<double> _calculateActiveListRespects({
    required UnifiedUser expert,
    required String category,
  }) async {
    // Placeholder: Return moderate score
    // In production, query user_respects table for lists in this category
    // Count active respects (recent respects = more active)
    return 0.5;
  }
}

/// Matching Signals Model
/// 
/// Contains all matching signal components for debugging and UI display
class MatchingSignals {
  final int eventsHostedCount;
  final double eventsHostedScore;
  final double averageRating;
  final int followersCount;
  final double followersScore;
  final double externalSocialScore;
  final double communityRecognitionScore;
  final double eventGrowthScore;
  final double activeListRespectsScore;
  final double localityWeight;

  const MatchingSignals({
    required this.eventsHostedCount,
    required this.eventsHostedScore,
    required this.averageRating,
    required this.followersCount,
    required this.followersScore,
    required this.externalSocialScore,
    required this.communityRecognitionScore,
    required this.eventGrowthScore,
    required this.activeListRespectsScore,
    required this.localityWeight,
  });

  factory MatchingSignals.empty() {
    return const MatchingSignals(
      eventsHostedCount: 0,
      eventsHostedScore: 0.0,
      averageRating: 0.0,
      followersCount: 0,
      followersScore: 0.0,
      externalSocialScore: 0.0,
      communityRecognitionScore: 0.0,
      eventGrowthScore: 0.0,
      activeListRespectsScore: 0.0,
      localityWeight: 0.0,
    );
  }
}

