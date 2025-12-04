import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/community_event_service.dart';

/// Community Event Upgrade Service
/// 
/// Manages upgrade eligibility evaluation and upgrade flow for community events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors from community events to local expert events
/// - Recognizes successful community building
/// - Creates natural progression path for event hosts
/// - Preserves event history and metrics during upgrade
/// 
/// **Upgrade Criteria:**
/// 1. **Frequency hosting** (host has hosted X events in Y time)
/// 2. **Strong following** (active returns, growth in size + diversity):
///    - Active returns: repeat attendees
///    - Growth in size: attendance increasing
///    - Diversity: diverse attendee base
/// 3. **User interaction patterns:**
///    - High engagement (views, saves, shares)
///    - Positive feedback/ratings
///    - Community building indicators
/// 
/// **Upgrade Flow:**
/// - Community event → Local expert event
/// - Update event type (community → local)
/// - Update host expertise (if needed)
/// - Preserve event history and metrics
/// - Notify host of upgrade
class CommunityEventUpgradeService {
  static const String _logName = 'CommunityEventUpgradeService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final CommunityEventService _communityEventService;
  final ExpertiseEventService _expertiseEventService;

  // Upgrade thresholds
  static const int minTimesHosted = 3; // Minimum times event must be hosted
  static const Duration hostingTimeWindow = Duration(days: 90); // 90 days
  static const double minRepeatAttendeeRate = 0.3; // 30% repeat attendees
  static const double minGrowthRate = 0.2; // 20% attendance growth
  static const double minDiversityScore = 0.5; // 50% diversity score
  static const double minEngagementScore = 0.6; // 60% engagement score
  static const double minAverageRating = 4.0; // 4.0/5.0 average rating
  static const double minUpgradeEligibilityScore = 0.7; // 70% overall score

  CommunityEventUpgradeService({
    CommunityEventService? communityEventService,
    ExpertiseEventService? expertiseEventService,
  })  : _communityEventService =
            communityEventService ?? CommunityEventService(),
        _expertiseEventService =
            expertiseEventService ?? ExpertiseEventService();

  /// Check if event is eligible for upgrade
  /// Returns true if event meets minimum upgrade criteria
  Future<bool> checkUpgradeEligibility(CommunityEvent event) async {
    try {
      _logger.info(
        'Checking upgrade eligibility for event ${event.id}',
        tag: _logName,
      );

      final score = await calculateUpgradeScore(event);
      final eligible = score >= minUpgradeEligibilityScore;

      if (eligible) {
        _logger.info(
          'Event is eligible for upgrade (score: ${score.toStringAsFixed(2)})',
          tag: _logName,
        );
      } else {
        _logger.info(
          'Event is not yet eligible for upgrade (score: ${score.toStringAsFixed(2)})',
          tag: _logName,
        );
      }

      return eligible;
    } catch (e) {
      _logger.error(
        'Error checking upgrade eligibility',
        error: e,
        tag: _logName,
      );
      return false;
    }
  }

  /// Calculate upgrade eligibility score (0.0 to 1.0)
  /// 
  /// **Score Components:**
  /// - Frequency hosting: 25% weight
  /// - Strong following (returns + growth + diversity): 30%)
  /// - Diversity: 15% weight
  /// - User interaction (engagement + feedback): 30% weight
  Future<double> calculateUpgradeScore(CommunityEvent event) async {
    try {
      _logger.info(
        'Calculating upgrade score for event ${event.id}',
        tag: _logName,
      );

      double score = 0.0;

      // 1. Frequency hosting (25% weight)
      final frequencyScore = _calculateFrequencyScore(event);
      score += frequencyScore * 0.25;

      // 2. Strong following (30% weight)
      final followingScore = _calculateFollowingScore(event);
      score += followingScore * 0.30;

      // 3. Diversity (15% weight)
      final diversityScore = event.diversityMetrics;
      score += diversityScore * 0.15;

      // 4. User interaction (30% weight)
      final interactionScore = _calculateInteractionScore(event);
      score += interactionScore * 0.30;

      final finalScore = score.clamp(0.0, 1.0);

      _logger.info(
        'Upgrade score calculated: ${finalScore.toStringAsFixed(2)}',
        tag: _logName,
      );

      return finalScore;
    } catch (e) {
      _logger.error(
        'Error calculating upgrade score',
        error: e,
        tag: _logName,
      );
      return 0.0;
    }
  }

  /// Calculate frequency hosting score
  /// 
  /// **Criteria:**
  /// - Host has hosted X events in Y time
  /// - Score based on times hosted (normalized to 0-1)
  double _calculateFrequencyScore(CommunityEvent event) {
    // Normalize times hosted (max at 10 times = 1.0)
    final timesHostedScore = (event.timesHosted / 10.0).clamp(0.0, 1.0);

    // Check if within time window (if event is recent)
    final now = DateTime.now();
    final daysSinceFirstHost = now.difference(event.createdAt).inDays;
    final withinTimeWindow = daysSinceFirstHost <= hostingTimeWindow.inDays;

    // Bonus for hosting frequently within time window
    if (withinTimeWindow && event.timesHosted >= minTimesHosted) {
      return 1.0; // Maximum score
    }

    return timesHostedScore;
  }

  /// Calculate following score (returns + growth + diversity)
  /// 
  /// **Criteria:**
  /// - Active returns: repeat attendees
  /// - Growth in size: attendance increasing
  /// - Diversity: diverse attendee base
  double _calculateFollowingScore(CommunityEvent event) {
    double score = 0.0;

    // 1. Repeat attendees (40% of following score)
    double repeatScore = 0.0;
    if (event.attendeeCount > 0) {
      final repeatRate =
          (event.repeatAttendeesCount / event.attendeeCount).clamp(0.0, 1.0);
      // Normalize to minRepeatAttendeeRate (0.3 = 1.0)
      repeatScore = (repeatRate / minRepeatAttendeeRate).clamp(0.0, 1.0);
    }
    score += repeatScore * 0.4;

    // 2. Growth metrics (40% of following score)
    // Normalize to minGrowthRate (0.2 = 1.0)
    final growthScore = (event.growthMetrics / minGrowthRate).clamp(0.0, 1.0);
    score += growthScore * 0.4;

    // 3. Diversity (20% of following score)
    // Normalize to minDiversityScore (0.5 = 1.0)
    final diversityScore =
        (event.diversityMetrics / minDiversityScore).clamp(0.0, 1.0);
    score += diversityScore * 0.2;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate interaction score (engagement + feedback)
  /// 
  /// **Criteria:**
  /// - High engagement (views, saves, shares)
  /// - Positive feedback/ratings
  /// - Community building indicators
  double _calculateInteractionScore(CommunityEvent event) {
    double score = 0.0;

    // 1. Engagement score (60% of interaction score)
    // Normalize to minEngagementScore (0.6 = 1.0)
    final engagementScore =
        (event.engagementScore / minEngagementScore).clamp(0.0, 1.0);
    score += engagementScore * 0.6;

    // 2. Average rating (30% of interaction score)
    if (event.averageRating != null) {
      // Normalize to minAverageRating (4.0 = 1.0, 5.0 = 1.0)
      final ratingScore =
          ((event.averageRating! - 3.0) / 2.0).clamp(0.0, 1.0); // 3.0-5.0 → 0.0-1.0
      score += ratingScore * 0.3;
    }

    // 3. Community building indicators (10% of interaction score)
    if (event.communityBuildingIndicators.isNotEmpty) {
      score += 0.1; // Bonus for community building
    }

    return score.clamp(0.0, 1.0);
  }

  /// Get which upgrade criteria are met
  /// Returns list of criteria names that are satisfied
  Future<List<String>> getUpgradeCriteria(CommunityEvent event) async {
    try {
      final criteria = <String>[];

      // Check frequency hosting
      if (event.timesHosted >= minTimesHosted) {
        criteria.add('Frequency hosting (${event.timesHosted} times hosted)');
      }

      // Check repeat attendees
      if (event.attendeeCount > 0) {
        final repeatRate = event.repeatAttendeesCount / event.attendeeCount;
        if (repeatRate >= minRepeatAttendeeRate) {
          criteria.add(
            'Active returns (${(repeatRate * 100).toStringAsFixed(0)}% repeat attendees)',
          );
        }
      }

      // Check growth
      if (event.growthMetrics >= minGrowthRate) {
        criteria.add(
          'Growth in size (${(event.growthMetrics * 100).toStringAsFixed(0)}% growth)',
        );
      }

      // Check diversity
      if (event.diversityMetrics >= minDiversityScore) {
        criteria.add(
          'Diversity (${(event.diversityMetrics * 100).toStringAsFixed(0)}% diverse)',
        );
      }

      // Check engagement
      if (event.engagementScore >= minEngagementScore) {
        criteria.add(
          'High engagement (${(event.engagementScore * 100).toStringAsFixed(0)}% engagement)',
        );
      }

      // Check rating
      if (event.averageRating != null &&
          event.averageRating! >= minAverageRating) {
        criteria.add(
          'Positive feedback (${event.averageRating!.toStringAsFixed(1)}/5.0 rating)',
        );
      }

      // Check community building
      if (event.communityBuildingIndicators.isNotEmpty) {
        criteria.add(
          'Community building (${event.communityBuildingIndicators.length} indicators)',
        );
      }

      return criteria;
    } catch (e) {
      _logger.error(
        'Error getting upgrade criteria',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Upgrade community event to local expert event
  /// 
  /// **Process:**
  /// 1. Validate upgrade eligibility
  /// 2. Create ExpertiseEvent from CommunityEvent
  /// 3. Preserve event history and metrics
  /// 4. Update host expertise (if needed)
  /// 5. Cancel original community event (or mark as upgraded)
  /// 6. Notify host of upgrade
  Future<ExpertiseEvent> upgradeToLocalEvent(
    CommunityEvent event,
    UnifiedUser host,
  ) async {
    try {
      _logger.info(
        'Upgrading community event to local expert event: ${event.id}',
        tag: _logName,
      );

      // Check upgrade eligibility
      final eligible = await checkUpgradeEligibility(event);
      if (!eligible) {
        throw Exception(
          'Event is not eligible for upgrade. Upgrade score must be at least ${(minUpgradeEligibilityScore * 100).toStringAsFixed(0)}%',
        );
      }

      // Verify host can host events (Local level or higher)
      if (!host.canHostEvents()) {
        throw Exception(
          'Host must have Local level or higher expertise to upgrade to local expert event',
        );
      }

      // Verify host has expertise in category
      if (!host.hasExpertiseIn(event.category)) {
        throw Exception(
          'Host must have expertise in ${event.category} to upgrade to local expert event',
        );
      }

      // Create upgraded event using ExpertiseEventService
      // Note: This creates a new ExpertiseEvent with a new ID.
      // In production, you may want to preserve the original event ID
      // or link the new event to the original for history tracking.
      final upgradedEvent = await _expertiseEventService.createEvent(
        host: host,
        title: event.title,
        description: event.description,
        category: event.category,
        eventType: event.eventType,
        startTime: event.startTime,
        endTime: event.endTime,
        spots: event.spots,
        location: event.location,
        latitude: event.latitude,
        longitude: event.longitude,
        maxAttendees: event.maxAttendees,
        price: event.price, // Keep original price (should be null/0 for community events)
        isPublic: event.isPublic,
      );

      // Update upgraded event with attendee information
      // (createEvent doesn't include attendeeIds, so we need to register them)
      // In production, you would transfer all attendees from community event
      for (final attendeeId in event.attendeeIds) {
        // Note: This would require getting UnifiedUser for each attendee
        // For now, we'll skip individual attendee registration
        // In production, implement proper attendee transfer
      }

      // Cancel original community event (mark as completed/upgraded)
      // This preserves the community event in history
      await _communityEventService.cancelCommunityEvent(event);

      _logger.info(
        'Community event upgraded to local expert event: ${upgradedEvent.id}',
        tag: _logName,
      );

      // TODO: Notify host of upgrade (via notification service)

      return upgradedEvent;
    } catch (e) {
      _logger.error(
        'Error upgrading community event to local expert event',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Generate upgraded event ID
  String _generateUpgradedEventId(String originalEventId) {
    // Keep original ID or generate new one with prefix
    // Using original ID with suffix to preserve history
    return '${originalEventId}_upgraded';
  }
}

