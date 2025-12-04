import 'package:equatable/equatable.dart';

/// Event Feedback Model
/// 
/// Represents feedback from an attendee, host, or partner about an event.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to continuous improvement
/// - Enables learning from experiences
/// - Supports community growth through feedback
/// 
/// **Usage:**
/// ```dart
/// final feedback = EventFeedback(
///   id: 'feedback-123',
///   eventId: 'event-456',
///   userId: 'user-789',
///   userRole: 'attendee',
///   overallRating: 4.5,
///   categoryRatings: {
///     'organization': 4.5,
///     'content_quality': 5.0,
///     'venue': 4.0,
///   },
///   submittedAt: DateTime.now(),
/// );
/// ```
class EventFeedback extends Equatable {
  /// Unique feedback identifier
  final String id;
  
  /// Event ID this feedback is for
  final String eventId;
  
  /// User ID who submitted feedback
  final String userId;
  
  /// Role of the user (attendee, host, partner)
  final String userRole;
  
  /// Overall rating (1-5 stars)
  final double overallRating;
  
  /// Detailed category ratings
  /// Examples: "organization", "content_quality", "venue", "value_for_money"
  final Map<String, double> categoryRatings;
  
  /// Free text comments
  final String? comments;
  
  /// What was great (highlights)
  final List<String>? highlights;
  
  /// What could be better (improvements)
  final List<String>? improvements;
  
  /// When feedback was submitted
  final DateTime submittedAt;
  
  /// Would attend again?
  final bool wouldAttendAgain;
  
  /// Would recommend to others?
  final bool wouldRecommend;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userRole,
    required this.overallRating,
    required this.categoryRatings,
    this.comments,
    this.highlights,
    this.improvements,
    required this.submittedAt,
    required this.wouldAttendAgain,
    required this.wouldRecommend,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  EventFeedback copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userRole,
    double? overallRating,
    Map<String, double>? categoryRatings,
    String? comments,
    List<String>? highlights,
    List<String>? improvements,
    DateTime? submittedAt,
    bool? wouldAttendAgain,
    bool? wouldRecommend,
    Map<String, dynamic>? metadata,
  }) {
    return EventFeedback(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      overallRating: overallRating ?? this.overallRating,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      comments: comments ?? this.comments,
      highlights: highlights ?? this.highlights,
      improvements: improvements ?? this.improvements,
      submittedAt: submittedAt ?? this.submittedAt,
      wouldAttendAgain: wouldAttendAgain ?? this.wouldAttendAgain,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userRole': userRole,
      'overallRating': overallRating,
      'categoryRatings': categoryRatings,
      'comments': comments,
      'highlights': highlights,
      'improvements': improvements,
      'submittedAt': submittedAt.toIso8601String(),
      'wouldAttendAgain': wouldAttendAgain,
      'wouldRecommend': wouldRecommend,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory EventFeedback.fromJson(Map<String, dynamic> json) {
    return EventFeedback(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      userRole: json['userRole'] as String,
      overallRating: (json['overallRating'] as num).toDouble(),
      categoryRatings: Map<String, double>.from(
        (json['categoryRatings'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      comments: json['comments'] as String?,
      highlights: json['highlights'] != null
          ? List<String>.from(json['highlights'] as List)
          : null,
      improvements: json['improvements'] != null
          ? List<String>.from(json['improvements'] as List)
          : null,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      wouldAttendAgain: json['wouldAttendAgain'] as bool? ?? false,
      wouldRecommend: json['wouldRecommend'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        userRole,
        overallRating,
        categoryRatings,
        comments,
        highlights,
        improvements,
        submittedAt,
        wouldAttendAgain,
        wouldRecommend,
        metadata,
      ];
}

/// Partner Rating Model
/// 
/// Represents a rating from one partner to another after an event.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to partnership quality
/// - Enables mutual feedback between partners
/// - Supports reputation building
/// 
/// **Usage:**
/// ```dart
/// final rating = PartnerRating(
///   id: 'rating-123',
///   eventId: 'event-456',
///   raterId: 'user-789',
///   ratedId: 'user-012',
///   partnershipRole: 'host',
///   overallRating: 4.5,
///   professionalism: 5.0,
///   communication: 4.0,
///   reliability: 4.5,
///   wouldPartnerAgain: 5.0,
///   submittedAt: DateTime.now(),
/// );
/// ```
class PartnerRating extends Equatable {
  /// Unique rating identifier
  final String id;
  
  /// Event ID this rating is for
  final String eventId;
  
  /// User ID who is rating (rater)
  final String raterId;
  
  /// User ID being rated
  final String ratedId;
  
  /// Partnership role (host, venue, sponsor, etc.)
  final String partnershipRole;
  
  /// Overall rating (1-5)
  final double overallRating;
  
  /// Professionalism rating (1-5)
  final double professionalism;
  
  /// Communication rating (1-5)
  final double communication;
  
  /// Reliability rating (1-5)
  final double reliability;
  
  /// Would partner again? (1-5 scale)
  final double wouldPartnerAgain;
  
  /// Positive feedback
  final String? positives;
  
  /// Improvement suggestions
  final String? improvements;
  
  /// When rating was submitted
  final DateTime submittedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const PartnerRating({
    required this.id,
    required this.eventId,
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
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  PartnerRating copyWith({
    String? id,
    String? eventId,
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
    Map<String, dynamic>? metadata,
  }) {
    return PartnerRating(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
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
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
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
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PartnerRating.fromJson(Map<String, dynamic> json) {
    return PartnerRating(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
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
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
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
        metadata,
      ];
}
