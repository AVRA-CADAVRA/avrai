import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';

/// Community Event Model
/// 
/// Extends existing ExpertiseEvent model to support non-expert community events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors for anyone to host community events (no expertise gate)
/// - Enables organic community building
/// - Creates natural path from community events to expert events
/// - Tracks event metrics for upgrade eligibility
/// 
/// **Key Features:**
/// - Extends ExpertiseEvent with community event support
/// - No payment on app (price must be null or 0.0, isPaid must be false)
/// - Public events only (isPublic must be true)
/// - Event metrics tracking (attendance, engagement, growth, diversity)
/// - Upgrade eligibility tracking (for upgrading to local expert events)
/// 
/// **Upgrade Path:**
/// - Community events can upgrade to local expert events when:
///   - Hosted frequently (recurring or multiple instances)
///   - Strong following (active returns, growth in size + diversity)
///   - High engagement (views, saves, shares, feedback)
///   - Community building indicators
class CommunityEvent extends ExpertiseEvent {
  /// Community event flag (always true for CommunityEvent)
  final bool isCommunityEvent;
  
  /// Host expertise level (null for non-experts)
  final ExpertiseLevel? hostExpertiseLevel;
  
  /// Event metrics tracking
  
  /// Engagement score (views, saves, shares) - 0.0 to 1.0
  final double engagementScore;
  
  /// Growth metrics (attendance growth over time) - 0.0 to 1.0
  final double growthMetrics;
  
  /// Diversity metrics (attendee diversity based on AI agents) - 0.0 to 1.0
  final double diversityMetrics;
  
  /// Upgrade eligibility tracking
  
  /// Whether event is eligible for upgrade to local expert event
  final bool isEligibleForUpgrade;
  
  /// Upgrade eligibility score (0.0 to 1.0)
  final double upgradeEligibilityScore;
  
  /// Which upgrade criteria are met
  final List<String> upgradeCriteria;
  
  /// Number of times this event has been hosted
  final int timesHosted;
  
  /// Number of repeat attendees
  final int repeatAttendeesCount;
  
  /// View count
  final int viewCount;
  
  /// Save count (users who saved this event)
  final int saveCount;
  
  /// Share count
  final int shareCount;
  
  /// Average rating (if ratings are collected)
  final double? averageRating;
  
  /// Positive feedback count
  final int positiveFeedbackCount;
  
  /// Community building indicators (e.g., community formed, club created)
  final List<String> communityBuildingIndicators;

  const CommunityEvent({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.eventType,
    required super.host,
    super.attendeeIds,
    super.attendeeCount,
    super.maxAttendees,
    required super.startTime,
    required super.endTime,
    super.spots,
    super.location,
    super.latitude,
    super.longitude,
    super.price,
    super.isPaid,
    super.isPublic,
    required super.createdAt,
    required super.updatedAt,
    super.status,
    this.isCommunityEvent = true,
    this.hostExpertiseLevel,
    this.engagementScore = 0.0,
    this.growthMetrics = 0.0,
    this.diversityMetrics = 0.0,
    this.isEligibleForUpgrade = false,
    this.upgradeEligibilityScore = 0.0,
    this.upgradeCriteria = const [],
    this.timesHosted = 1,
    this.repeatAttendeesCount = 0,
    this.viewCount = 0,
    this.saveCount = 0,
    this.shareCount = 0,
    this.averageRating,
    this.positiveFeedbackCount = 0,
    this.communityBuildingIndicators = const [],
  }) : assert(
          price == null || price == 0.0,
          'Community events cannot have payment on app (price must be null or 0.0)',
        ),
        assert(
          isPaid == false,
          'Community events cannot be paid (isPaid must be false)',
        ),
        assert(
          isPublic == true,
          'Community events must be public (isPublic must be true)',
        );

  /// Create CommunityEvent from ExpertiseEvent
  factory CommunityEvent.fromExpertiseEvent({
    required ExpertiseEvent event,
    ExpertiseLevel? hostExpertiseLevel,
    double engagementScore = 0.0,
    double growthMetrics = 0.0,
    double diversityMetrics = 0.0,
    bool isEligibleForUpgrade = false,
    double upgradeEligibilityScore = 0.0,
    List<String>? upgradeCriteria,
    int timesHosted = 1,
    int repeatAttendeesCount = 0,
    int viewCount = 0,
    int saveCount = 0,
    int shareCount = 0,
    double? averageRating,
    int positiveFeedbackCount = 0,
    List<String>? communityBuildingIndicators,
  }) {
    // Validate community event requirements
    if (event.price != null && event.price! > 0.0) {
      throw Exception(
        'Community events cannot have payment on app (price must be null or 0.0)',
      );
    }
    if (event.isPaid) {
      throw Exception('Community events cannot be paid (isPaid must be false)');
    }
    if (!event.isPublic) {
      throw Exception('Community events must be public (isPublic must be true)');
    }

    return CommunityEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      category: event.category,
      eventType: event.eventType,
      host: event.host,
      attendeeIds: event.attendeeIds,
      attendeeCount: event.attendeeCount,
      maxAttendees: event.maxAttendees,
      startTime: event.startTime,
      endTime: event.endTime,
      spots: event.spots,
      location: event.location,
      latitude: event.latitude,
      longitude: event.longitude,
      price: event.price,
      isPaid: event.isPaid,
      isPublic: event.isPublic,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      status: event.status,
      hostExpertiseLevel: hostExpertiseLevel,
      engagementScore: engagementScore,
      growthMetrics: growthMetrics,
      diversityMetrics: diversityMetrics,
      isEligibleForUpgrade: isEligibleForUpgrade,
      upgradeEligibilityScore: upgradeEligibilityScore,
      upgradeCriteria: upgradeCriteria ?? [],
      timesHosted: timesHosted,
      repeatAttendeesCount: repeatAttendeesCount,
      viewCount: viewCount,
      saveCount: saveCount,
      shareCount: shareCount,
      averageRating: averageRating,
      positiveFeedbackCount: positiveFeedbackCount,
      communityBuildingIndicators: communityBuildingIndicators ?? [],
    );
  }

  /// Check if host is a non-expert
  bool get isNonExpertHost => hostExpertiseLevel == null;

  /// Check if event has growth indicators
  bool get hasGrowth => growthMetrics > 0.0;

  /// Check if event has diversity indicators
  bool get hasDiversity => diversityMetrics > 0.0;

  /// Check if event has high engagement
  bool get hasHighEngagement => engagementScore >= 0.7;

  /// Get overall event quality score (0.0 to 1.0)
  double get overallQualityScore {
    double score = 0.0;
    
    // Attendance growth (30%)
    score += growthMetrics * 0.3;
    
    // Engagement (30%)
    score += engagementScore * 0.3;
    
    // Diversity (20%)
    score += diversityMetrics * 0.2;
    
    // Repeat attendees (10%)
    if (attendeeCount > 0) {
      final repeatRate = (repeatAttendeesCount / attendeeCount).clamp(0.0, 1.0);
      score += repeatRate * 0.1;
    }
    
    // Times hosted (10%) - normalized to 0-1 (max at 10 times)
    score += (timesHosted / 10.0).clamp(0.0, 1.0) * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'isCommunityEvent': isCommunityEvent,
      'hostExpertiseLevel': hostExpertiseLevel?.name,
      'engagementScore': engagementScore,
      'growthMetrics': growthMetrics,
      'diversityMetrics': diversityMetrics,
      'isEligibleForUpgrade': isEligibleForUpgrade,
      'upgradeEligibilityScore': upgradeEligibilityScore,
      'upgradeCriteria': upgradeCriteria,
      'timesHosted': timesHosted,
      'repeatAttendeesCount': repeatAttendeesCount,
      'viewCount': viewCount,
      'saveCount': saveCount,
      'shareCount': shareCount,
      'averageRating': averageRating,
      'positiveFeedbackCount': positiveFeedbackCount,
      'communityBuildingIndicators': communityBuildingIndicators,
    });
    return baseJson;
  }

  /// Create from JSON
  factory CommunityEvent.fromJson(
    Map<String, dynamic> json,
    UnifiedUser host,
  ) {
    final baseEvent = ExpertiseEvent.fromJson(json, host);
    
    ExpertiseLevel? hostExpertiseLevel;
    if (json['hostExpertiseLevel'] != null) {
      try {
        hostExpertiseLevel = ExpertiseLevel.values.firstWhere(
          (level) => level.name == json['hostExpertiseLevel'],
        );
      } catch (e) {
        hostExpertiseLevel = null;
      }
    }

    return CommunityEvent.fromExpertiseEvent(
      event: baseEvent,
      hostExpertiseLevel: hostExpertiseLevel,
      engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
      growthMetrics: (json['growthMetrics'] as num?)?.toDouble() ?? 0.0,
      diversityMetrics: (json['diversityMetrics'] as num?)?.toDouble() ?? 0.0,
      isEligibleForUpgrade: json['isEligibleForUpgrade'] as bool? ?? false,
      upgradeEligibilityScore:
          (json['upgradeEligibilityScore'] as num?)?.toDouble() ?? 0.0,
      upgradeCriteria: List<String>.from(json['upgradeCriteria'] ?? []),
      timesHosted: json['timesHosted'] as int? ?? 1,
      repeatAttendeesCount: json['repeatAttendeesCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      saveCount: json['saveCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      positiveFeedbackCount: json['positiveFeedbackCount'] as int? ?? 0,
      communityBuildingIndicators:
          List<String>.from(json['communityBuildingIndicators'] ?? []),
    );
  }

  /// Copy with method
  @override
  CommunityEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    ExpertiseEventType? eventType,
    UnifiedUser? host,
    List<String>? attendeeIds,
    int? attendeeCount,
    int? maxAttendees,
    DateTime? startTime,
    DateTime? endTime,
    List<Spot>? spots,
    String? location,
    double? latitude,
    double? longitude,
    double? price,
    bool? isPaid,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    EventStatus? status,
    bool? isCommunityEvent,
    ExpertiseLevel? hostExpertiseLevel,
    double? engagementScore,
    double? growthMetrics,
    double? diversityMetrics,
    bool? isEligibleForUpgrade,
    double? upgradeEligibilityScore,
    List<String>? upgradeCriteria,
    int? timesHosted,
    int? repeatAttendeesCount,
    int? viewCount,
    int? saveCount,
    int? shareCount,
    double? averageRating,
    int? positiveFeedbackCount,
    List<String>? communityBuildingIndicators,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      host: host ?? this.host,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      spots: spots ?? this.spots,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      price: price ?? this.price,
      isPaid: isPaid ?? this.isPaid,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isCommunityEvent: isCommunityEvent ?? this.isCommunityEvent,
      hostExpertiseLevel: hostExpertiseLevel ?? this.hostExpertiseLevel,
      engagementScore: engagementScore ?? this.engagementScore,
      growthMetrics: growthMetrics ?? this.growthMetrics,
      diversityMetrics: diversityMetrics ?? this.diversityMetrics,
      isEligibleForUpgrade: isEligibleForUpgrade ?? this.isEligibleForUpgrade,
      upgradeEligibilityScore:
          upgradeEligibilityScore ?? this.upgradeEligibilityScore,
      upgradeCriteria: upgradeCriteria ?? this.upgradeCriteria,
      timesHosted: timesHosted ?? this.timesHosted,
      repeatAttendeesCount: repeatAttendeesCount ?? this.repeatAttendeesCount,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      shareCount: shareCount ?? this.shareCount,
      averageRating: averageRating ?? this.averageRating,
      positiveFeedbackCount:
          positiveFeedbackCount ?? this.positiveFeedbackCount,
      communityBuildingIndicators:
          communityBuildingIndicators ?? this.communityBuildingIndicators,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        isCommunityEvent,
        hostExpertiseLevel,
        engagementScore,
        growthMetrics,
        diversityMetrics,
        isEligibleForUpgrade,
        upgradeEligibilityScore,
        upgradeCriteria,
        timesHosted,
        repeatAttendeesCount,
        viewCount,
        saveCount,
        shareCount,
        averageRating,
        positiveFeedbackCount,
        communityBuildingIndicators,
      ];
}

