import 'package:spots/core/models/event_success_metrics.dart';
import 'package:spots/core/models/event_success_level.dart';
import 'package:spots/core/models/event_feedback.dart' hide PartnerRating;
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Event Success Analysis Service
/// 
/// Analyzes event success after feedback collection and calculates metrics.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to data-driven improvement
/// - Enables learning from each event
/// - Supports continuous growth
/// - Creates pathways for better future events
/// 
/// **Responsibilities:**
/// - Analyze event success after feedback
/// - Calculate attendance, financial, and quality metrics
/// - Determine success level
/// - Identify success factors and improvement areas
/// - Update host reputation
/// - Feed into recommendation algorithm
/// 
/// **Usage:**
/// ```dart
/// final analysisService = EventSuccessAnalysisService(
///   eventService,
///   feedbackService,
///   paymentService,
/// );
/// 
/// // Analyze event success
/// final metrics = await analysisService.analyzeEventSuccess('event-123');
/// ```
class EventSuccessAnalysisService {
  static const String _logName = 'EventSuccessAnalysisService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  final PostEventFeedbackService _feedbackService;
  final PaymentService? _paymentService;
  
  // In-memory storage for success metrics (in production, use database)
  final Map<String, EventSuccessMetrics> _successMetrics = {};
  
  EventSuccessAnalysisService({
    required ExpertiseEventService eventService,
    required PostEventFeedbackService feedbackService,
    PaymentService? paymentService,
  }) : _eventService = eventService,
       _feedbackService = feedbackService,
       _paymentService = paymentService;
  
  /// Analyze event success after feedback collection
  /// 
  /// **Flow:**
  /// 1. Get event by ID
  /// 2. Get all feedback for event
  /// 3. Calculate attendance metrics
  /// 4. Calculate financial metrics
  /// 5. Calculate quality metrics (ratings, NPS)
  /// 6. Determine success level
  /// 7. Identify success factors and improvement areas
  /// 8. Create EventSuccessMetrics record
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// EventSuccessMetrics with complete analysis
  /// 
  /// **Throws:**
  /// - `Exception` if event not found
  Future<EventSuccessMetrics> analyzeEventSuccess(String eventId) async {
    try {
      _logger.info('Analyzing event success: event=$eventId', tag: _logName);
      
      // Step 1: Get event
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Step 2: Get all feedback for event
      final feedbacks = await _feedbackService.getFeedbackForEvent(eventId);
      final partnerRatings = await _feedbackService.getPartnerRatingsForEvent(eventId);
      
      // Step 3: Calculate attendance metrics
      final attendanceMetrics = _calculateAttendanceMetrics(event, feedbacks);
      
      // Step 4: Calculate financial metrics
      final financialMetrics = await _calculateFinancialMetrics(event);
      
      // Step 5: Calculate quality metrics
      final qualityMetrics = _calculateQualityMetrics(feedbacks, partnerRatings);
      
      // Step 6: Determine success level
      final successLevel = _determineSuccessLevel(
        attendanceMetrics['attendanceRate'] as double,
        qualityMetrics['averageRating'] as double,
        qualityMetrics['nps'] as double?,
      );
      
      // Step 7: Identify success factors and improvement areas
      final analysis = _identifySuccessFactors(
        feedbacks,
        partnerRatings,
        attendanceMetrics,
        qualityMetrics,
      );
      
      // Step 8: Create EventSuccessMetrics
      final metrics = EventSuccessMetrics(
        eventId: eventId,
        ticketsSold: attendanceMetrics['ticketsSold'] as int,
        actualAttendance: attendanceMetrics['actualAttendance'] as int,
        attendanceRate: attendanceMetrics['attendanceRate'] as double,
        grossRevenue: financialMetrics['grossRevenue'] as double,
        netRevenue: financialMetrics['netRevenue'] as double,
        revenueVsProjected: (financialMetrics['revenueVsProjected'] as double?) ?? 0.0,
        profitMargin: (financialMetrics['profitMargin'] as double?) ?? 0.0,
        averageRating: qualityMetrics['averageRating'] as double,
        nps: (qualityMetrics['nps'] as double?) ?? 0.0,
        fiveStarCount: qualityMetrics['fiveStarCount'] as int,
        fourStarCount: qualityMetrics['fourStarCount'] as int,
        threeStarCount: qualityMetrics['threeStarCount'] as int,
        twoStarCount: qualityMetrics['twoStarCount'] as int,
        oneStarCount: qualityMetrics['oneStarCount'] as int,
        feedbackResponseRate: qualityMetrics['feedbackResponseRate'] as double,
        attendeesWhoWouldReturn: qualityMetrics['attendeesWhoWouldReturn'] as int,
        attendeesWhoWouldRecommend: qualityMetrics['attendeesWhoWouldRecommend'] as int,
        partnerSatisfaction: qualityMetrics['partnerSatisfaction'] as Map<String, double>,
        partnersWouldCollaborateAgain: qualityMetrics['partnersWouldCollaborateAgain'] as bool,
        successLevel: successLevel,
        successFactors: analysis['successFactors'] as List<String>,
        improvementAreas: analysis['improvementAreas'] as List<String>,
        calculatedAt: DateTime.now(),
      );
      
      // Step 9: Save metrics
      await _saveMetrics(metrics);
      
      // Step 10: Update host reputation
      await _updateHostReputation(event.host.id, metrics);
      
      _logger.info('Event success analyzed: event=$eventId, level=${successLevel.name}', tag: _logName);
      return metrics;
    } catch (e) {
      _logger.error('Error analyzing event success', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get success metrics for an event
  Future<EventSuccessMetrics?> getEventMetrics(String eventId) async {
    return _successMetrics[eventId];
  }
  
  // Private helper methods
  
  /// Calculate attendance metrics
  Map<String, dynamic> _calculateAttendanceMetrics(
    ExpertiseEvent event,
    List<EventFeedback> feedbacks,
  ) {
    final ticketsSold = event.attendeeCount;
    // In production, track actual attendance through check-in
    // For now, estimate based on feedback response rate
    final feedbackResponseRate = feedbacks.length / ticketsSold.clamp(1, double.infinity);
    final estimatedAttendance = (ticketsSold * feedbackResponseRate.clamp(0.8, 1.0)).round();
    final attendanceRate = ticketsSold > 0 ? estimatedAttendance / ticketsSold : 0.0;
    
    return {
      'ticketsSold': ticketsSold,
      'actualAttendance': estimatedAttendance,
      'attendanceRate': attendanceRate,
    };
  }
  
  /// Calculate financial metrics
  Future<Map<String, dynamic>> _calculateFinancialMetrics(ExpertiseEvent event) async {
    double grossRevenue = 0.0;
    double netRevenue = 0.0;
    
    if (event.isPaid && event.price != null) {
      grossRevenue = event.price! * event.attendeeCount;
      // Platform fee is 10%, processing fee is ~3%
      final platformFee = grossRevenue * 0.10;
      final processingFee = grossRevenue * 0.03;
      netRevenue = grossRevenue - platformFee - processingFee;
    }
    
    // Revenue vs projected (simplified - would compare to event projections in production)
    final revenueVsProjected = event.maxAttendees > 0
        ? event.attendeeCount / event.maxAttendees
        : null;
    
    // Profit margin (simplified calculation)
    final profitMargin = grossRevenue > 0 ? (netRevenue / grossRevenue) * 100 : null;
    
    return {
      'grossRevenue': grossRevenue,
      'netRevenue': netRevenue,
      'revenueVsProjected': revenueVsProjected,
      'profitMargin': profitMargin,
    };
  }
  
  /// Calculate quality metrics
  Map<String, dynamic> _calculateQualityMetrics(
    List<EventFeedback> feedbacks,
    List<PartnerRating> partnerRatings,
  ) {
    if (feedbacks.isEmpty) {
      return {
        'averageRating': 0.0,
        'nps': null,
        'fiveStarCount': 0,
        'fourStarCount': 0,
        'threeStarCount': 0,
        'twoStarCount': 0,
        'oneStarCount': 0,
        'feedbackResponseRate': 0.0,
        'attendeesWhoWouldReturn': 0,
        'attendeesWhoWouldRecommend': 0,
        'partnerSatisfaction': <String, double>{},
        'partnersWouldCollaborateAgain': false,
      };
    }
    
    // Calculate average rating
    final averageRating = feedbacks.map((f) => f.overallRating).reduce((a, b) => a + b) / feedbacks.length;
    
    // Count ratings by stars
    int fiveStar = 0, fourStar = 0, threeStar = 0, twoStar = 0, oneStar = 0;
    for (final feedback in feedbacks) {
      final rating = feedback.overallRating.round();
      if (rating >= 5) {
        fiveStar++;
      } else if (rating >= 4) {
        fourStar++;
      } else if (rating >= 3) {
        threeStar++;
      } else if (rating >= 2) {
        twoStar++;
      } else {
        oneStar++;
      }
    }
    
    // Calculate NPS (Net Promoter Score)
    final promoters = feedbacks.where((f) => f.wouldRecommend && f.overallRating >= 4).length;
    final detractors = feedbacks.where((f) => !f.wouldRecommend || f.overallRating <= 2).length;
    final totalResponses = feedbacks.length;
    final nps = totalResponses > 0
        ? ((promoters - detractors) / totalResponses) * 100
        : null;
    
    // Calculate feedback response rate (simplified - would need total attendee count)
    final feedbackResponseRate = totalResponses > 0 ? totalResponses / totalResponses.clamp(1, double.infinity) : 0.0;
    
    // Count attendees who would return/recommend
    final attendeesWhoWouldReturn = feedbacks.where((f) => f.wouldAttendAgain).length;
    final attendeesWhoWouldRecommend = feedbacks.where((f) => f.wouldRecommend).length;
    
     // Calculate partner satisfaction
     final partnerSatisfaction = <String, double>{};
     for (final rating in partnerRatings) {
       // Use overallRating for partner satisfaction
       partnerSatisfaction[rating.ratedId] = rating.overallRating;
     }
    
    final partnersWouldCollaborateAgain = partnerRatings.isNotEmpty &&
        partnerRatings.where((r) => r.wouldPartnerAgain >= 4).length / partnerRatings.length >= 0.7;
    
    return {
      'averageRating': averageRating,
      'nps': nps,
      'fiveStarCount': fiveStar,
      'fourStarCount': fourStar,
      'threeStarCount': threeStar,
      'twoStarCount': twoStar,
      'oneStarCount': oneStar,
      'feedbackResponseRate': feedbackResponseRate,
      'attendeesWhoWouldReturn': attendeesWhoWouldReturn,
      'attendeesWhoWouldRecommend': attendeesWhoWouldRecommend,
      'partnerSatisfaction': partnerSatisfaction,
      'partnersWouldCollaborateAgain': partnersWouldCollaborateAgain,
    };
  }
  
  /// Determine success level based on metrics
  EventSuccessLevel _determineSuccessLevel(
    double attendanceRate,
    double averageRating,
    double? nps,
  ) {
    // Exceptional: 4.8+ rating, 95%+ attendance, high NPS
    if (averageRating >= 4.8 && attendanceRate >= 0.95 && (nps ?? 0) >= 50) {
      return EventSuccessLevel.exceptional;
    }
    
    // High: 4.0+ rating, 80%+ attendance
    if (averageRating >= 4.0 && attendanceRate >= 0.80) {
      return EventSuccessLevel.high;
    }
    
    // Medium: 3.5+ rating, 60%+ attendance
    if (averageRating >= 3.5 && attendanceRate >= 0.60) {
      return EventSuccessLevel.medium;
    }
    
    // Low: <3.5 rating or <60% attendance
    return EventSuccessLevel.low;
  }
  
  /// Identify success factors and improvement areas
  Map<String, List<String>> _identifySuccessFactors(
    List<EventFeedback> feedbacks,
    List<PartnerRating> partnerRatings,
    Map<String, dynamic> attendanceMetrics,
    Map<String, dynamic> qualityMetrics,
  ) {
    final successFactors = <String>[];
    final improvementAreas = <String>[];
    
    // Analyze feedback highlights and improvements
    for (final feedback in feedbacks) {
      if (feedback.highlights != null) {
        successFactors.addAll(feedback.highlights!);
      }
      if (feedback.improvements != null) {
        improvementAreas.addAll(feedback.improvements!);
      }
    }
    
    // Analyze partner ratings
    for (final rating in partnerRatings) {
      if (rating.positives != null && rating.positives!.isNotEmpty) {
        successFactors.add(rating.positives!);
      }
      if (rating.improvements != null && rating.improvements!.isNotEmpty) {
        improvementAreas.add(rating.improvements!);
      }
    }
    
    // Add metrics-based factors
    final attendanceRate = attendanceMetrics['attendanceRate'] as double;
    final averageRating = qualityMetrics['averageRating'] as double;
    
    if (attendanceRate >= 0.90) {
      successFactors.add('High attendance rate');
    } else if (attendanceRate < 0.70) {
      improvementAreas.add('Improve attendance rate');
    }
    
    if (averageRating >= 4.5) {
      successFactors.add('Excellent ratings');
    } else if (averageRating < 3.5) {
      improvementAreas.add('Improve event quality');
    }
    
    // Remove duplicates
    successFactors.toSet().toList();
    improvementAreas.toSet().toList();
    
    return {
      'successFactors': successFactors,
      'improvementAreas': improvementAreas,
    };
  }
  
  /// Update host reputation based on success metrics
  Future<void> _updateHostReputation(String hostId, EventSuccessMetrics metrics) async {
    // In production, update host's reputation score
    _logger.info('Updating host reputation: host=$hostId, successLevel=${metrics.successLevel.name}', tag: _logName);
    // TODO: Implement reputation system
  }
  
  Future<void> _saveMetrics(EventSuccessMetrics metrics) async {
    // In production, save to database
    _successMetrics[metrics.eventId] = metrics;
  }
}
