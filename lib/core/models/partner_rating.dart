import 'package:equatable/equatable.dart';

/// Partner Rating Model
/// 
/// Represents a mutual rating between partners (user, business, sponsor)
/// after a partnership event. Enables reputation building and vibe matching.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to trusted partnerships
/// - Enables reputation building
/// - Supports vibe matching algorithm
/// - Creates pathways for future collaboration
/// 
/// **Usage:**
/// ```dart
/// final rating = PartnerRating(
///   id: 'rating-123',
///   eventId: 'event-456',
///   partnershipId: 'partnership-789',
///   raterId: 'user-1',
///   ratedId: 'business-1',
///   partnershipRole: 'venue',
///   overallRating: 4.5,
///   professionalism: 5.0,
///   communication: 4.5,
///   reliability: 4.0,
///   wouldPartnerAgain: 5.0,
///   positives: 'Great collaboration, easy to work with',
///   improvements: 'More communication upfront would help',
/// );
/// ```
class PartnerRating extends Equatable {
  /// Unique rating identifier
  final String id;
  
  /// Event ID this rating is for
  final String eventId;
  
  /// Partnership ID this rating is for
  final String partnershipId;
  
  /// User ID who is rating (rater)
  final String raterId;
  
  /// User/business ID who is being rated (rated)
  final String ratedId;
  
  /// Partnership role of the rated party (host, venue, sponsor, etc.)
  final String partnershipRole;
  
  /// Overall rating (1-5 stars)
  final double overallRating;
  
  /// Professionalism rating (1-5 stars)
  final double professionalism;
  
  /// Communication rating (1-5 stars)
  final double communication;
  
  /// Reliability rating (1-5 stars)
  final double reliability;
  
  /// Would partner again? (1-5 stars, 5 = definitely yes)
  final double wouldPartnerAgain;
  
  /// Positive feedback/strengths
  final String? positives;
  
  /// Improvement suggestions
  final String? improvements;
  
  /// When rating was submitted
  final DateTime submittedAt;
  
  /// When rating was last updated
  final DateTime updatedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const PartnerRating({
    required this.id,
    required this.eventId,
    required this.partnershipId,
    required this.raterId,
    required this.ratedId,
    required this.partnershipRole,
    required this.overallRating,
    required this.professionalism,
    required this.communication,
    required this.reliability,
    required this.wouldPartnerAgain,
    this.positives,
    this.improvements,
    required this.submittedAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  PartnerRating copyWith({
    String? id,
    String? eventId,
    String? partnershipId,
    String? raterId,
    String? ratedId,
    String? partnershipRole,
    double? overallRating,
    double? professionalism,
    double? communication,
    double? reliability,
    double? wouldPartnerAgain,
    String? positives,
    String? improvements,
    DateTime? submittedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PartnerRating(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      partnershipId: partnershipId ?? this.partnershipId,
      raterId: raterId ?? this.raterId,
      ratedId: ratedId ?? this.ratedId,
      partnershipRole: partnershipRole ?? this.partnershipRole,
      overallRating: overallRating ?? this.overallRating,
      professionalism: professionalism ?? this.professionalism,
      communication: communication ?? this.communication,
      reliability: reliability ?? this.reliability,
      wouldPartnerAgain: wouldPartnerAgain ?? this.wouldPartnerAgain,
      positives: positives ?? this.positives,
      improvements: improvements ?? this.improvements,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'partnershipId': partnershipId,
      'raterId': raterId,
      'ratedId': ratedId,
      'partnershipRole': partnershipRole,
      'overallRating': overallRating,
      'professionalism': professionalism,
      'communication': communication,
      'reliability': reliability,
      'wouldPartnerAgain': wouldPartnerAgain,
      'positives': positives,
      'improvements': improvements,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PartnerRating.fromJson(Map<String, dynamic> json) {
    return PartnerRating(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      partnershipId: json['partnershipId'] as String,
      raterId: json['raterId'] as String,
      ratedId: json['ratedId'] as String,
      partnershipRole: json['partnershipRole'] as String,
      overallRating: (json['overallRating'] as num).toDouble(),
      professionalism: (json['professionalism'] as num).toDouble(),
      communication: (json['communication'] as num).toDouble(),
      reliability: (json['reliability'] as num).toDouble(),
      wouldPartnerAgain: (json['wouldPartnerAgain'] as num).toDouble(),
      positives: json['positives'] as String?,
      improvements: json['improvements'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Get average detailed rating (professionalism, communication, reliability)
  double get averageDetailedRating {
    return (professionalism + communication + reliability) / 3.0;
  }

  /// Check if rating is positive (overall >= 4)
  bool get isPositive => overallRating >= 4.0;

  /// Check if rating is negative (overall < 3)
  bool get isNegative => overallRating < 3.0;

  /// Check if would partner again (wouldPartnerAgain >= 4)
  bool get isLikelyToPartnerAgain => wouldPartnerAgain >= 4.0;

  @override
  List<Object?> get props => [
        id,
        eventId,
        partnershipId,
        raterId,
        ratedId,
        partnershipRole,
        overallRating,
        professionalism,
        communication,
        reliability,
        wouldPartnerAgain,
        positives,
        improvements,
        submittedAt,
        updatedAt,
        metadata,
      ];
}
