import 'package:spots/core/models/event_feedback.dart' hide PartnerRating;
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Post-Event Feedback Service
/// 
/// Handles feedback collection and partner ratings after events.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to continuous improvement
/// - Enables learning from experiences
/// - Supports community growth through feedback
/// - Feeds into vibe matching algorithm
/// 
/// **Responsibilities:**
/// - Schedule feedback collection (2 hours after event)
/// - Send feedback requests to attendees
/// - Send partner mutual rating requests
/// - Submit attendee feedback
/// - Submit partner ratings
/// - Update event aggregate ratings
/// - Update host/partner reputation
/// 
/// **Usage:**
/// ```dart
/// final feedbackService = PostEventFeedbackService(
///   eventService,
///   partnershipService,
/// );
/// 
/// // Schedule feedback collection
/// await feedbackService.scheduleFeedbackCollection('event-123');
/// 
/// // Submit feedback
/// final feedback = await feedbackService.submitFeedback(
///   eventId: 'event-123',
///   userId: 'user-456',
///   overallRating: 4.5,
///   categoryRatings: {'organization': 4.5, 'content_quality': 5.0},
///   wouldAttendAgain: true,
///   wouldRecommend: true,
/// );
/// ```
class PostEventFeedbackService {
  static const String _logName = 'PostEventFeedbackService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final ExpertiseEventService _eventService;
  final PartnershipService? _partnershipService;
  
  // In-memory storage for feedback (in production, use database)
  final Map<String, EventFeedback> _feedback = {};
  final Map<String, PartnerRating> _partnerRatings = {};
  
  PostEventFeedbackService({
    required ExpertiseEventService eventService,
    PartnershipService? partnershipService,
  }) : _eventService = eventService,
       _partnershipService = partnershipService;
  
  /// Schedule feedback collection after event
  /// 
  /// **Flow:**
  /// 1. Get event details
  /// 2. Calculate feedback time (2 hours after event ends)
  /// 3. Schedule notification/request
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// 
  /// **Returns:**
  /// Scheduled feedback time
  Future<DateTime> scheduleFeedbackCollection(String eventId) async {
    try {
      _logger.info('Scheduling feedback collection: event=$eventId', tag: _logName);
      
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Schedule for 2 hours after event ends
      final feedbackTime = event.endTime.add(const Duration(hours: 2));
      
      // In production, schedule notification/request
      await _scheduleNotification(
        eventId: eventId,
        scheduledFor: feedbackTime,
        type: NotificationType.feedbackRequest,
      );
      
      _logger.info('Feedback collection scheduled: event=$eventId, time=$feedbackTime', tag: _logName);
      
      return feedbackTime;
    } catch (e) {
      _logger.error('Error scheduling feedback collection', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Send feedback requests to all attendees and partners
  /// 
  /// **Flow:**
  /// 1. Get event and attendees
  /// 2. Get event partners
  /// 3. Send feedback requests to attendees
  /// 4. Send partner mutual rating requests
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  Future<void> sendFeedbackRequests(String eventId) async {
    try {
      _logger.info('Sending feedback requests: event=$eventId', tag: _logName);
      
      final event = await _eventService.getEventById(eventId);
      if (event == null) {
        throw Exception('Event not found: $eventId');
      }
      
      // Get attendees
      final attendees = event.attendeeIds;
      
      // Request attendee feedback
      for (final attendeeId in attendees) {
        await _sendFeedbackRequest(
          userId: attendeeId,
          eventId: eventId,
          type: FeedbackType.attendee,
        );
      }
      
      // Get partners and request mutual ratings
      if (_partnershipService != null) {
        final partnerships = await _partnershipService!.getPartnershipsForEvent(eventId);
        
        for (final partnership in partnerships) {
          // Request rating from user to business
          await _sendPartnerRatingRequest(
            partnerId: partnership.userId,
            eventId: eventId,
            otherPartnerId: partnership.businessId,
            partnershipRole: 'business',
          );
          
          // Request rating from business to user
          await _sendPartnerRatingRequest(
            partnerId: partnership.businessId,
            eventId: eventId,
            otherPartnerId: partnership.userId,
            partnershipRole: 'host',
          );
        }
      }
      
      _logger.info('Feedback requests sent: event=$eventId, attendees=${attendees.length}', tag: _logName);
    } catch (e) {
      _logger.error('Error sending feedback requests', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Submit attendee feedback
  /// 
  /// **Flow:**
  /// 1. Create feedback record
  /// 2. Save feedback
  /// 3. Update event aggregate ratings
  /// 4. Update host reputation
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `userId`: User ID submitting feedback
  /// - `overallRating`: Overall rating (1-5)
  /// - `categoryRatings`: Category ratings map
  /// - `comments`: Optional comments
  /// - `highlights`: Optional highlights
  /// - `improvements`: Optional improvements
  /// - `wouldAttendAgain`: Would attend again?
  /// - `wouldRecommend`: Would recommend?
  /// 
  /// **Returns:**
  /// Created feedback record
  Future<EventFeedback> submitFeedback({
    required String eventId,
    required String userId,
    required double overallRating,
    required Map<String, double> categoryRatings,
    String? comments,
    List<String>? highlights,
    List<String>? improvements,
    required bool wouldAttendAgain,
    required bool wouldRecommend,
  }) async {
    try {
      _logger.info('Submitting feedback: event=$eventId, user=$userId', tag: _logName);
      
      // Step 1: Create feedback record
      final feedback = EventFeedback(
        id: 'feedback_${_uuid.v4()}',
        eventId: eventId,
        userId: userId,
        userRole: 'attendee',
        overallRating: overallRating,
        categoryRatings: categoryRatings,
        comments: comments,
        highlights: highlights,
        improvements: improvements,
        submittedAt: DateTime.now(),
        wouldAttendAgain: wouldAttendAgain,
        wouldRecommend: wouldRecommend,
      );
      
      // Step 2: Save feedback
      await _saveFeedback(feedback);
      
      // Step 3: Update event aggregate ratings
      await _updateEventRatings(eventId);
      
      // Step 4: Update host rating
      await _updateHostRating(eventId);
      
      _logger.info('Feedback submitted: ${feedback.id}', tag: _logName);
      
      return feedback;
    } catch (e) {
      _logger.error('Error submitting feedback', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Submit partner rating
  /// 
  /// **Flow:**
  /// 1. Create partner rating record
  /// 2. Save rating
  /// 3. Update partner's overall rating
  /// 4. Feed into vibe matching algorithm
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID
  /// - `raterId`: User ID rating
  /// - `ratedId`: User ID being rated
  /// - `partnershipRole`: Role of rated partner
  /// - `overallRating`: Overall rating (1-5)
  /// - `professionalism`: Professionalism rating (1-5)
  /// - `communication`: Communication rating (1-5)
  /// - `reliability`: Reliability rating (1-5)
  /// - `wouldPartnerAgain`: Would partner again? (1-5)
  /// - `positives`: Optional positive feedback
  /// - `improvements`: Optional improvement suggestions
  /// 
  /// **Returns:**
  /// Created partner rating record
  Future<PartnerRating> submitPartnerRating({
    required String eventId,
    required String raterId,
    required String ratedId,
    required String partnershipRole,
    required double overallRating,
    required double professionalism,
    required double communication,
    required double reliability,
    required double wouldPartnerAgain,
    String? positives,
    String? improvements,
  }) async {
    try {
      _logger.info('Submitting partner rating: event=$eventId, rater=$raterId, rated=$ratedId', tag: _logName);
      
      // Step 1: Create partner rating record
      final now = DateTime.now();
      final rating = PartnerRating(
        id: 'rating_${_uuid.v4()}',
        eventId: eventId,
        partnershipId: 'partnership_${eventId}_${ratedId}', // Generate partnership ID
        raterId: raterId,
        ratedId: ratedId,
        partnershipRole: partnershipRole,
        overallRating: overallRating,
        professionalism: professionalism,
        communication: communication,
        reliability: reliability,
        wouldPartnerAgain: wouldPartnerAgain,
        positives: positives,
        improvements: improvements,
        submittedAt: now,
        updatedAt: now,
      );
      
      // Step 2: Save rating
      await _savePartnerRating(rating);
      
      // Step 3: Update partner's overall rating
      await _updatePartnerReputation(ratedId);
      
      // Step 4: Feed into vibe matching algorithm
      await _updateVibeCompatibility(raterId, ratedId, rating);
      
      _logger.info('Partner rating submitted: ${rating.id}', tag: _logName);
      
      return rating;
    } catch (e) {
      _logger.error('Error submitting partner rating', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get feedback for an event
  Future<List<EventFeedback>> getFeedbackForEvent(String eventId) async {
    try {
      return _feedback.values
          .where((f) => f.eventId == eventId)
          .toList();
    } catch (e) {
      _logger.error('Error getting feedback for event', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get feedback for an event (alias for EventSuccessAnalysisService)
  Future<List<EventFeedback>> getEventFeedback(String eventId) async {
    return getFeedbackForEvent(eventId);
  }
  
  /// Get partner ratings for an event
  Future<List<PartnerRating>> getPartnerRatingsForEvent(String eventId) async {
    try {
      return _partnerRatings.values
          .where((r) => r.eventId == eventId)
          .toList();
    } catch (e) {
      _logger.error('Error getting partner ratings for event', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get partner ratings for an event (alias for EventSuccessAnalysisService)
  Future<List<PartnerRating>> getEventPartnerRatings(String eventId) async {
    return getPartnerRatingsForEvent(eventId);
  }
  
  // Private helper methods
  
  Future<void> _saveFeedback(EventFeedback feedback) async {
    // In production, save to database
    _feedback[feedback.id] = feedback;
  }
  
  Future<void> _savePartnerRating(PartnerRating rating) async {
    // In production, save to database
    _partnerRatings[rating.id] = rating;
  }
  
  Future<void> _updateEventRatings(String eventId) async {
    // In production, calculate and update aggregate ratings
    final allFeedback = await getFeedbackForEvent(eventId);
    if (allFeedback.isEmpty) {
      return;
    }
    
    final avgRating = allFeedback
        .map((f) => f.overallRating)
        .reduce((a, b) => a + b) / allFeedback.length;
    
    _logger.info('Updated event ratings: event=$eventId, avgRating=${avgRating.toStringAsFixed(2)}', tag: _logName);
    // TODO: Update event model with aggregate ratings
  }
  
  Future<void> _updateHostRating(String eventId) async {
    // In production, update host's reputation/rating
    final event = await _eventService.getEventById(eventId);
    if (event == null) {
      return;
    }
    
    _logger.info('Updated host rating: host=${event.host.id}, event=$eventId', tag: _logName);
    // TODO: Update host reputation in user model
  }
  
  Future<void> _updatePartnerReputation(String partnerId) async {
    // In production, update partner's overall reputation
    final ratings = _partnerRatings.values
        .where((r) => r.ratedId == partnerId)
        .toList();
    
    if (ratings.isEmpty) {
      return;
    }
    
    final avgRating = ratings
        .map((r) => r.overallRating)
        .reduce((a, b) => a + b) / ratings.length;
    
    _logger.info('Updated partner reputation: partner=$partnerId, avgRating=${avgRating.toStringAsFixed(2)}', tag: _logName);
    // TODO: Update partner reputation in business/user model
  }
  
  Future<void> _updateVibeCompatibility(String raterId, String ratedId, PartnerRating rating) async {
    // In production, feed into vibe matching algorithm
    _logger.info('Updating vibe compatibility: rater=$raterId, rated=$ratedId, rating=${rating.overallRating}', tag: _logName);
    // TODO: Integrate with vibe matching algorithm
  }
  
  Future<void> _scheduleNotification({
    required String eventId,
    required DateTime scheduledFor,
    required NotificationType type,
  }) async {
    // In production, schedule notification
    _logger.info('Scheduled notification: event=$eventId, time=$scheduledFor, type=$type', tag: _logName);
    // TODO: Implement notification scheduling
  }
  
  Future<void> _sendFeedbackRequest({
    required String userId,
    required String eventId,
    required FeedbackType type,
  }) async {
    // In production, send notification/request
    _logger.info('Sending feedback request: user=$userId, event=$eventId, type=$type', tag: _logName);
    // TODO: Implement notification system
  }
  
  Future<void> _sendPartnerRatingRequest({
    required String partnerId,
    required String eventId,
    required String otherPartnerId,
    required String partnershipRole,
  }) async {
    // In production, send notification/request
    _logger.info('Sending partner rating request: partner=$partnerId, event=$eventId, other=$otherPartnerId', tag: _logName);
    // TODO: Implement notification system
  }
}

// Helper enums
enum NotificationType {
  feedbackRequest,
  partnerRatingRequest,
}

enum FeedbackType {
  attendee,
  host,
  partner,
}
