import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_matching_score.dart';

/// Event Recommendation Model
/// 
/// Represents a personalized event recommendation for a user.
/// Includes relevance score, recommendation reason, and preference match details.
/// 
/// **Philosophy:** Recommendations open doors to events users will enjoy,
/// balancing familiar preferences with exploration opportunities.
class EventRecommendation extends Equatable {
  /// Recommended event
  final ExpertiseEvent event;
  
  /// Relevance score (0.0 to 1.0)
  /// Higher score = more relevant to user
  final double relevanceScore;
  
  /// Recommendation reason
  final RecommendationReason reason;
  
  /// Preference match details
  final PreferenceMatchDetails preferenceMatch;
  
  /// Matching score (from EventMatchingService)
  final EventMatchingScore? matchingScore;
  
  /// Whether this is an exploration recommendation
  /// (outside user's typical behavior)
  final bool isExploration;
  
  /// Timestamp when recommendation was generated
  final DateTime generatedAt;

  const EventRecommendation({
    required this.event,
    required this.relevanceScore,
    required this.reason,
    required this.preferenceMatch,
    this.matchingScore,
    this.isExploration = false,
    required this.generatedAt,
  });

  /// Check if recommendation is highly relevant (>= 0.7)
  bool get isHighlyRelevant => relevanceScore >= 0.7;

  /// Check if recommendation is moderately relevant (0.4 to 0.7)
  bool get isModeratelyRelevant => relevanceScore >= 0.4 && relevanceScore < 0.7;

  /// Check if recommendation is weakly relevant (< 0.4)
  bool get isWeaklyRelevant => relevanceScore < 0.4;

  /// Get recommendation reason display text
  String get reasonDisplayText {
    switch (reason) {
      case RecommendationReason.categoryPreference:
        return 'Matches your interest in ${event.category}';
      case RecommendationReason.localityPreference:
        return 'In your preferred area';
      case RecommendationReason.scopePreference:
        return 'Matches your preferred scope';
      case RecommendationReason.eventTypePreference:
        return 'You enjoy ${event.getEventTypeDisplayName()} events';
      case RecommendationReason.localExpert:
        return 'From a local expert in your area';
      case RecommendationReason.matchingScore:
        return 'Highly rated by likeminded people';
      case RecommendationReason.exploration:
        return 'Try something new';
      case RecommendationReason.crossLocality:
        return 'In a connected area you visit';
      case RecommendationReason.combined:
        return 'Matches multiple preferences';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': event.id,
      'relevanceScore': relevanceScore,
      'reason': reason.name,
      'preferenceMatch': preferenceMatch.toJson(),
      'matchingScore': matchingScore?.toJson(),
      'isExploration': isExploration,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  /// Note: Requires event lookup - event must be provided separately
  factory EventRecommendation.fromJson(
    Map<String, dynamic> json,
    ExpertiseEvent event,
  ) {
    return EventRecommendation(
      event: event,
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
      reason: RecommendationReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => RecommendationReason.combined,
      ),
      preferenceMatch: PreferenceMatchDetails.fromJson(
        json['preferenceMatch'] as Map<String, dynamic>,
      ),
      matchingScore: json['matchingScore'] != null
          ? EventMatchingScore.fromJson(json['matchingScore'] as Map<String, dynamic>)
          : null,
      isExploration: json['isExploration'] as bool? ?? false,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  /// Copy with method
  EventRecommendation copyWith({
    ExpertiseEvent? event,
    double? relevanceScore,
    RecommendationReason? reason,
    PreferenceMatchDetails? preferenceMatch,
    EventMatchingScore? matchingScore,
    bool? isExploration,
    DateTime? generatedAt,
  }) {
    return EventRecommendation(
      event: event ?? this.event,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      reason: reason ?? this.reason,
      preferenceMatch: preferenceMatch ?? this.preferenceMatch,
      matchingScore: matchingScore ?? this.matchingScore,
      isExploration: isExploration ?? this.isExploration,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  List<Object?> get props => [
        event,
        relevanceScore,
        reason,
        preferenceMatch,
        matchingScore,
        isExploration,
        generatedAt,
      ];
}

/// Recommendation Reason Enum
/// 
/// Represents why an event was recommended to a user.
enum RecommendationReason {
  /// Matches user's category preference
  categoryPreference,
  
  /// Matches user's locality preference
  localityPreference,
  
  /// Matches user's scope preference
  scopePreference,
  
  /// Matches user's event type preference
  eventTypePreference,
  
  /// From a local expert (user prefers local experts)
  localExpert,
  
  /// High matching score (likeminded people)
  matchingScore,
  
  /// Exploration opportunity (outside typical behavior)
  exploration,
  
  /// Cross-locality connection (user visits this area)
  crossLocality,
  
  /// Combined reasons (multiple factors)
  combined,
}

/// Preference Match Details
/// 
/// Details about how an event matches user preferences.
class PreferenceMatchDetails extends Equatable {
  /// Category match score (0.0 to 1.0)
  final double categoryMatch;
  
  /// Locality match score (0.0 to 1.0)
  final double localityMatch;
  
  /// Scope match score (0.0 to 1.0)
  final double scopeMatch;
  
  /// Event type match score (0.0 to 1.0)
  final double eventTypeMatch;
  
  /// Local expert preference match (0.0 to 1.0)
  final double localExpertMatch;
  
  /// Overall preference match score (0.0 to 1.0)
  /// Weighted combination of all match scores
  double get overallMatch {
    return (
      categoryMatch * 0.3 +
      localityMatch * 0.25 +
      scopeMatch * 0.2 +
      eventTypeMatch * 0.15 +
      localExpertMatch * 0.1
    ).clamp(0.0, 1.0);
  }

  const PreferenceMatchDetails({
    required this.categoryMatch,
    required this.localityMatch,
    required this.scopeMatch,
    required this.eventTypeMatch,
    required this.localExpertMatch,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categoryMatch': categoryMatch,
      'localityMatch': localityMatch,
      'scopeMatch': scopeMatch,
      'eventTypeMatch': eventTypeMatch,
      'localExpertMatch': localExpertMatch,
      'overallMatch': overallMatch,
    };
  }

  /// Create from JSON
  factory PreferenceMatchDetails.fromJson(Map<String, dynamic> json) {
    return PreferenceMatchDetails(
      categoryMatch: (json['categoryMatch'] as num?)?.toDouble() ?? 0.0,
      localityMatch: (json['localityMatch'] as num?)?.toDouble() ?? 0.0,
      scopeMatch: (json['scopeMatch'] as num?)?.toDouble() ?? 0.0,
      eventTypeMatch: (json['eventTypeMatch'] as num?)?.toDouble() ?? 0.0,
      localExpertMatch: (json['localExpertMatch'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Copy with method
  PreferenceMatchDetails copyWith({
    double? categoryMatch,
    double? localityMatch,
    double? scopeMatch,
    double? eventTypeMatch,
    double? localExpertMatch,
  }) {
    return PreferenceMatchDetails(
      categoryMatch: categoryMatch ?? this.categoryMatch,
      localityMatch: localityMatch ?? this.localityMatch,
      scopeMatch: scopeMatch ?? this.scopeMatch,
      eventTypeMatch: eventTypeMatch ?? this.eventTypeMatch,
      localExpertMatch: localExpertMatch ?? this.localExpertMatch,
    );
  }

  @override
  List<Object?> get props => [
        categoryMatch,
        localityMatch,
        scopeMatch,
        eventTypeMatch,
        localExpertMatch,
      ];
}

