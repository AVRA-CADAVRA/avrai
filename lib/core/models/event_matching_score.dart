import 'package:equatable/equatable.dart';

/// Event Matching Score Model
/// 
/// Represents a matching score between an expert and a user for event discovery.
/// Includes breakdown of matching signals, locality-specific weighting, and local expert priority boost.
/// 
/// **Philosophy:** Local experts are prioritized in their locality to help users find
/// events from experts who know their area best. This opens doors to authentic local experiences.
class EventMatchingScore extends Equatable {
  /// Overall matching score (0.0 to 1.0)
  final double score;
  
  /// Matching signals breakdown
  final MatchingSignals signals;
  
  /// Locality-specific weighting applied
  final double localityWeight;
  
  /// Local expert priority boost (0.0 to 1.0)
  /// Higher boost for local experts hosting in their locality
  final double localExpertPriorityBoost;
  
  /// Category being matched
  final String category;
  
  /// Locality where matching is being evaluated
  final String? locality;
  
  /// Timestamp when score was calculated
  final DateTime calculatedAt;

  const EventMatchingScore({
    required this.score,
    required this.signals,
    required this.localityWeight,
    required this.localExpertPriorityBoost,
    required this.category,
    this.locality,
    required this.calculatedAt,
  });

  /// Check if score indicates a strong match (>= 0.7)
  bool get isStrongMatch => score >= 0.7;

  /// Check if score indicates a moderate match (0.4 to 0.7)
  bool get isModerateMatch => score >= 0.4 && score < 0.7;

  /// Check if score indicates a weak match (< 0.4)
  bool get isWeakMatch => score < 0.4;

  /// Get score breakdown for debugging/UI display
  Map<String, dynamic> get breakdown {
    return {
      'overallScore': score,
      'signals': signals.toJson(),
      'localityWeight': localityWeight,
      'localExpertPriorityBoost': localExpertPriorityBoost,
      'category': category,
      'locality': locality,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'signals': signals.toJson(),
      'localityWeight': localityWeight,
      'localExpertPriorityBoost': localExpertPriorityBoost,
      'category': category,
      'locality': locality,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EventMatchingScore.fromJson(Map<String, dynamic> json) {
    return EventMatchingScore(
      score: (json['score'] as num).toDouble(),
      signals: MatchingSignals.fromJson(json['signals'] as Map<String, dynamic>),
      localityWeight: (json['localityWeight'] as num).toDouble(),
      localExpertPriorityBoost: (json['localExpertPriorityBoost'] as num).toDouble(),
      category: json['category'] as String,
      locality: json['locality'] as String?,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  /// Copy with method
  EventMatchingScore copyWith({
    double? score,
    MatchingSignals? signals,
    double? localityWeight,
    double? localExpertPriorityBoost,
    String? category,
    String? locality,
    DateTime? calculatedAt,
  }) {
    return EventMatchingScore(
      score: score ?? this.score,
      signals: signals ?? this.signals,
      localityWeight: localityWeight ?? this.localityWeight,
      localExpertPriorityBoost: localExpertPriorityBoost ?? this.localExpertPriorityBoost,
      category: category ?? this.category,
      locality: locality ?? this.locality,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  List<Object?> get props => [
        score,
        signals,
        localityWeight,
        localExpertPriorityBoost,
        category,
        locality,
        calculatedAt,
      ];
}

/// Matching Signals Breakdown
/// 
/// Represents the individual signals that contribute to the matching score.
/// These are not formal rankings but signals that indicate expert quality and relevance.
class MatchingSignals extends Equatable {
  /// Events hosted count (more events = higher signal)
  final int eventsHostedCount;
  
  /// Average event rating from attendees (0.0 to 5.0)
  final double averageEventRating;
  
  /// Followers count (users following the expert)
  final int followersCount;
  
  /// External social following (if available)
  final int? externalSocialFollowing;
  
  /// Community recognition score (partnerships, collaborations)
  final double communityRecognitionScore;
  
  /// Event growth signal (community building - attendance growth over time)
  final double eventGrowthSignal;
  
  /// Active list respects (users adding events to their lists)
  final int activeListRespects;

  const MatchingSignals({
    required this.eventsHostedCount,
    required this.averageEventRating,
    required this.followersCount,
    this.externalSocialFollowing,
    required this.communityRecognitionScore,
    required this.eventGrowthSignal,
    required this.activeListRespects,
  });

  /// Calculate raw signal score (before locality weighting)
  double get rawSignalScore {
    double score = 0.0;
    
    // Events hosted (normalized to 0-1, max at 50 events)
    score += (eventsHostedCount / 50.0).clamp(0.0, 1.0) * 0.2;
    
    // Average rating (normalized to 0-1)
    score += (averageEventRating / 5.0) * 0.25;
    
    // Followers (normalized to 0-1, max at 1000 followers)
    score += (followersCount / 1000.0).clamp(0.0, 1.0) * 0.15;
    
    // External social following (if available, normalized to 0-1, max at 10000)
    if (externalSocialFollowing != null) {
      score += (externalSocialFollowing! / 10000.0).clamp(0.0, 1.0) * 0.1;
    }
    
    // Community recognition
    score += communityRecognitionScore * 0.15;
    
    // Event growth signal
    score += eventGrowthSignal * 0.1;
    
    // Active list respects (normalized to 0-1, max at 100)
    score += (activeListRespects / 100.0).clamp(0.0, 1.0) * 0.05;
    
    return score.clamp(0.0, 1.0);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventsHostedCount': eventsHostedCount,
      'averageEventRating': averageEventRating,
      'followersCount': followersCount,
      'externalSocialFollowing': externalSocialFollowing,
      'communityRecognitionScore': communityRecognitionScore,
      'eventGrowthSignal': eventGrowthSignal,
      'activeListRespects': activeListRespects,
      'rawSignalScore': rawSignalScore,
    };
  }

  /// Create from JSON
  factory MatchingSignals.fromJson(Map<String, dynamic> json) {
    return MatchingSignals(
      eventsHostedCount: json['eventsHostedCount'] as int? ?? 0,
      averageEventRating: (json['averageEventRating'] as num?)?.toDouble() ?? 0.0,
      followersCount: json['followersCount'] as int? ?? 0,
      externalSocialFollowing: json['externalSocialFollowing'] as int?,
      communityRecognitionScore: (json['communityRecognitionScore'] as num?)?.toDouble() ?? 0.0,
      eventGrowthSignal: (json['eventGrowthSignal'] as num?)?.toDouble() ?? 0.0,
      activeListRespects: json['activeListRespects'] as int? ?? 0,
    );
  }

  /// Copy with method
  MatchingSignals copyWith({
    int? eventsHostedCount,
    double? averageEventRating,
    int? followersCount,
    int? externalSocialFollowing,
    double? communityRecognitionScore,
    double? eventGrowthSignal,
    int? activeListRespects,
  }) {
    return MatchingSignals(
      eventsHostedCount: eventsHostedCount ?? this.eventsHostedCount,
      averageEventRating: averageEventRating ?? this.averageEventRating,
      followersCount: followersCount ?? this.followersCount,
      externalSocialFollowing: externalSocialFollowing ?? this.externalSocialFollowing,
      communityRecognitionScore: communityRecognitionScore ?? this.communityRecognitionScore,
      eventGrowthSignal: eventGrowthSignal ?? this.eventGrowthSignal,
      activeListRespects: activeListRespects ?? this.activeListRespects,
    );
  }

  @override
  List<Object?> get props => [
        eventsHostedCount,
        averageEventRating,
        followersCount,
        externalSocialFollowing,
        communityRecognitionScore,
        eventGrowthSignal,
        activeListRespects,
      ];
}

