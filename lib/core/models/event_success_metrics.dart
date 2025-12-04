import 'package:equatable/equatable.dart';
import 'package:spots/core/models/event_success_level.dart';

/// Event Success Metrics Model
/// 
/// Represents comprehensive success analysis for an event.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to learning and improvement
/// - Enables data-driven event hosting
/// - Supports reputation building
/// - Feeds into recommendation algorithm
/// 
/// **Usage:**
/// ```dart
/// final metrics = EventSuccessMetrics(
///   eventId: 'event-123',
///   ticketsSold: 50,
///   actualAttendance: 45,
///   attendanceRate: 0.90,
///   averageRating: 4.5,
///   nps: 70,
///   successLevel: EventSuccessLevel.successful,
/// );
/// ```
class EventSuccessMetrics extends Equatable {
  /// Event ID
  final String eventId;
  
  /// Number of tickets sold
  final int ticketsSold;
  
  /// Actual attendance count
  final int actualAttendance;
  
  /// Attendance rate (actual / sold)
  final double attendanceRate;
  
  /// Gross revenue
  final double grossRevenue;
  
  /// Net revenue (after fees)
  final double netRevenue;
  
  /// Revenue vs projected
  final double revenueVsProjected;
  
  /// Profit margin
  final double profitMargin;
  
  /// Average rating (1-5)
  final double averageRating;
  
  /// Net Promoter Score (-100 to 100)
  final double nps;
  
  /// Rating distribution
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;
  
  /// Feedback response rate
  final double feedbackResponseRate;
  
  /// Number of attendees who would return
  final int attendeesWhoWouldReturn;
  
  /// Number of attendees who would recommend
  final int attendeesWhoWouldRecommend;
  
  /// Partner satisfaction scores (partnerId -> rating)
  final Map<String, double> partnerSatisfaction;
  
  /// Whether partners would collaborate again
  final bool partnersWouldCollaborateAgain;
  
  /// Calculated success level
  final EventSuccessLevel successLevel;
  
  /// Success factors (what went well)
  final List<String> successFactors;
  
  /// Improvement areas (what to improve)
  final List<String> improvementAreas;
  
  /// When metrics were calculated
  final DateTime calculatedAt;
  
  /// Optional metadata
  final Map<String, dynamic> metadata;

  const EventSuccessMetrics({
    required this.eventId,
    required this.ticketsSold,
    required this.actualAttendance,
    required this.attendanceRate,
    required this.grossRevenue,
    required this.netRevenue,
    required this.revenueVsProjected,
    required this.profitMargin,
    required this.averageRating,
    required this.nps,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
    required this.feedbackResponseRate,
    required this.attendeesWhoWouldReturn,
    required this.attendeesWhoWouldRecommend,
    required this.partnerSatisfaction,
    required this.partnersWouldCollaborateAgain,
    required this.successLevel,
    required this.successFactors,
    required this.improvementAreas,
    required this.calculatedAt,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  EventSuccessMetrics copyWith({
    String? eventId,
    int? ticketsSold,
    int? actualAttendance,
    double? attendanceRate,
    double? grossRevenue,
    double? netRevenue,
    double? revenueVsProjected,
    double? profitMargin,
    double? averageRating,
    double? nps,
    int? fiveStarCount,
    int? fourStarCount,
    int? threeStarCount,
    int? twoStarCount,
    int? oneStarCount,
    double? feedbackResponseRate,
    int? attendeesWhoWouldReturn,
    int? attendeesWhoWouldRecommend,
    Map<String, double>? partnerSatisfaction,
    bool? partnersWouldCollaborateAgain,
    EventSuccessLevel? successLevel,
    List<String>? successFactors,
    List<String>? improvementAreas,
    DateTime? calculatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return EventSuccessMetrics(
      eventId: eventId ?? this.eventId,
      ticketsSold: ticketsSold ?? this.ticketsSold,
      actualAttendance: actualAttendance ?? this.actualAttendance,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      grossRevenue: grossRevenue ?? this.grossRevenue,
      netRevenue: netRevenue ?? this.netRevenue,
      revenueVsProjected: revenueVsProjected ?? this.revenueVsProjected,
      profitMargin: profitMargin ?? this.profitMargin,
      averageRating: averageRating ?? this.averageRating,
      nps: nps ?? this.nps,
      fiveStarCount: fiveStarCount ?? this.fiveStarCount,
      fourStarCount: fourStarCount ?? this.fourStarCount,
      threeStarCount: threeStarCount ?? this.threeStarCount,
      twoStarCount: twoStarCount ?? this.twoStarCount,
      oneStarCount: oneStarCount ?? this.oneStarCount,
      feedbackResponseRate: feedbackResponseRate ?? this.feedbackResponseRate,
      attendeesWhoWouldReturn: attendeesWhoWouldReturn ?? this.attendeesWhoWouldReturn,
      attendeesWhoWouldRecommend: attendeesWhoWouldRecommend ?? this.attendeesWhoWouldRecommend,
      partnerSatisfaction: partnerSatisfaction ?? this.partnerSatisfaction,
      partnersWouldCollaborateAgain: partnersWouldCollaborateAgain ?? this.partnersWouldCollaborateAgain,
      successLevel: successLevel ?? this.successLevel,
      successFactors: successFactors ?? this.successFactors,
      improvementAreas: improvementAreas ?? this.improvementAreas,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'ticketsSold': ticketsSold,
      'actualAttendance': actualAttendance,
      'attendanceRate': attendanceRate,
      'grossRevenue': grossRevenue,
      'netRevenue': netRevenue,
      'revenueVsProjected': revenueVsProjected,
      'profitMargin': profitMargin,
      'averageRating': averageRating,
      'nps': nps,
      'fiveStarCount': fiveStarCount,
      'fourStarCount': fourStarCount,
      'threeStarCount': threeStarCount,
      'twoStarCount': twoStarCount,
      'oneStarCount': oneStarCount,
      'feedbackResponseRate': feedbackResponseRate,
      'attendeesWhoWouldReturn': attendeesWhoWouldReturn,
      'attendeesWhoWouldRecommend': attendeesWhoWouldRecommend,
      'partnerSatisfaction': partnerSatisfaction,
      'partnersWouldCollaborateAgain': partnersWouldCollaborateAgain,
      'successLevel': successLevel.name,
      'successFactors': successFactors,
      'improvementAreas': improvementAreas,
      'calculatedAt': calculatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory EventSuccessMetrics.fromJson(Map<String, dynamic> json) {
    return EventSuccessMetrics(
      eventId: json['eventId'] as String,
      ticketsSold: json['ticketsSold'] as int? ?? 0,
      actualAttendance: json['actualAttendance'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 0.0,
      grossRevenue: (json['grossRevenue'] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json['netRevenue'] as num?)?.toDouble() ?? 0.0,
      revenueVsProjected: (json['revenueVsProjected'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      nps: (json['nps'] as num?)?.toDouble() ?? 0.0,
      fiveStarCount: json['fiveStarCount'] as int? ?? 0,
      fourStarCount: json['fourStarCount'] as int? ?? 0,
      threeStarCount: json['threeStarCount'] as int? ?? 0,
      twoStarCount: json['twoStarCount'] as int? ?? 0,
      oneStarCount: json['oneStarCount'] as int? ?? 0,
      feedbackResponseRate: (json['feedbackResponseRate'] as num?)?.toDouble() ?? 0.0,
      attendeesWhoWouldReturn: json['attendeesWhoWouldReturn'] as int? ?? 0,
      attendeesWhoWouldRecommend: json['attendeesWhoWouldRecommend'] as int? ?? 0,
      partnerSatisfaction: Map<String, double>.from(
        (json['partnerSatisfaction'] as Map?)?.map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ) ?? {},
      ),
      partnersWouldCollaborateAgain: json['partnersWouldCollaborateAgain'] as bool? ?? false,
      successLevel: EventSuccessLevel.fromJson(json['successLevel'] as String),
      successFactors: List<String>.from(json['successFactors'] ?? []),
      improvementAreas: List<String>.from(json['improvementAreas'] ?? []),
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String)
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        ticketsSold,
        actualAttendance,
        attendanceRate,
        grossRevenue,
        netRevenue,
        revenueVsProjected,
        profitMargin,
        averageRating,
        nps,
        fiveStarCount,
        fourStarCount,
        threeStarCount,
        twoStarCount,
        oneStarCount,
        feedbackResponseRate,
        attendeesWhoWouldReturn,
        attendeesWhoWouldRecommend,
        partnerSatisfaction,
        partnersWouldCollaborateAgain,
        successLevel,
        successFactors,
        improvementAreas,
        calculatedAt,
        metadata,
      ];
}
