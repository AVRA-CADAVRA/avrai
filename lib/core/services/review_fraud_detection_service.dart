import 'package:spots/core/models/review_fraud_score.dart';
import 'package:spots/core/models/fraud_signal.dart';
import 'package:spots/core/models/fraud_recommendation.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/logger.dart';
import 'package:uuid/uuid.dart';

/// Review Fraud Detection Service
/// 
/// Detects fake or fraudulent reviews/feedback submissions.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to authentic feedback
/// - Enables review quality control
/// - Supports platform trust
/// - Creates pathways for genuine user experiences
/// 
/// **Responsibilities:**
/// - Detect fake reviews
/// - Check for all 5-star reviews
/// - Check for same-day clustering
/// - Check for generic text
/// - Check for similar language patterns
/// - Calculate risk score
/// - Generate recommendations
/// 
/// **Usage:**
/// ```dart
/// final reviewFraudService = ReviewFraudDetectionService(feedbackService);
/// 
/// // Analyze reviews for fraud
/// final fraudScore = await reviewFraudService.analyzeReviews('event-123');
/// ```
class ReviewFraudDetectionService {
  static const String _logName = 'ReviewFraudDetectionService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  final Uuid _uuid = const Uuid();
  
  final PostEventFeedbackService _feedbackService;
  
  // In-memory storage for review fraud scores (in production, use database)
  final Map<String, ReviewFraudScore> _fraudScores = {};
  
  ReviewFraudDetectionService({
    required PostEventFeedbackService feedbackService,
  }) : _feedbackService = feedbackService;
  
  /// Analyze reviews for fraud signals
  /// 
  /// **Flow:**
  /// 1. Get all feedback for event
  /// 2. Check for fraud signals
  ///    - All 5-star reviews
  ///    - Same-day clustering
  ///    - Generic text
  ///    - Similar language patterns
  /// 3. Calculate risk score
  /// 4. Generate recommendation
  /// 5. Create and save ReviewFraudScore
  /// 
  /// **Parameters:**
  /// - `eventId`: Event ID to analyze reviews for
  /// 
  /// **Returns:**
  /// ReviewFraudScore with risk assessment
  Future<ReviewFraudScore> analyzeReviews(String eventId) async {
    try {
      _logger.info('Analyzing reviews for fraud: event=$eventId', tag: _logName);
      
      // Step 1: Get all feedback for event
      final feedbacks = await _feedbackService.getFeedbackForEvent(eventId);
      
      if (feedbacks.isEmpty) {
        // No reviews yet, return low-risk score
        return ReviewFraudScore(
          id: 'review-fraud_${_uuid.v4()}',
          feedbackId: eventId, // Using eventId as feedbackId for aggregate analysis
          riskScore: 0.0,
          signals: [],
          recommendation: FraudRecommendation.approve,
          calculatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      // Step 2: Check for fraud signals
      final signals = <FraudSignal>[];
      double riskScore = 0.0;
      
      // Check 1: All 5-star reviews
      if (_hasAllFiveStarReviews(feedbacks)) {
        signals.add(FraudSignal.allFiveStar);
        riskScore += FraudSignal.allFiveStar.riskWeight;
      }
      
      // Check 2: Same-day clustering
      if (_hasSameDayClustering(feedbacks)) {
        signals.add(FraudSignal.sameDayClustering);
        riskScore += FraudSignal.sameDayClustering.riskWeight;
      }
      
      // Check 3: Generic reviews
      if (_hasGenericReviews(feedbacks)) {
        signals.add(FraudSignal.genericReviews);
        riskScore += FraudSignal.genericReviews.riskWeight;
      }
      
      // Check 4: Similar language patterns
      if (_hasSimilarLanguage(feedbacks)) {
        signals.add(FraudSignal.similarLanguage);
        riskScore += FraudSignal.similarLanguage.riskWeight;
      }
      
      // Check 5: Coordinated reviews (combination of signals)
      if (_hasCoordinatedReviews(feedbacks, signals)) {
        signals.add(FraudSignal.coordinatedReviews);
        riskScore += FraudSignal.coordinatedReviews.riskWeight;
      }
      
      // Clamp risk score to 0.0-1.0
      riskScore = riskScore.clamp(0.0, 1.0);
      
      // Step 3: Generate recommendation
      final recommendation = FraudRecommendation.fromRiskScore(riskScore);
      
      // Step 4: Create ReviewFraudScore
      final fraudScore = ReviewFraudScore(
        id: 'review-fraud_${_uuid.v4()}',
        feedbackId: eventId, // Using eventId for aggregate analysis
        riskScore: riskScore,
        signals: signals,
        recommendation: recommendation,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Step 5: Save fraud score
      await _saveFraudScore(fraudScore);
      
      _logger.info('Review fraud analysis complete: event=$eventId, riskScore=${riskScore.toStringAsFixed(2)}, recommendation=${recommendation.name}', tag: _logName);
      
      return fraudScore;
    } catch (e) {
      _logger.error('Error analyzing reviews for fraud', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Analyze reviews for a specific user
  /// 
  /// **Flow:**
  /// 1. Get all feedback from user
  /// 2. Apply same fraud detection checks
  /// 3. Return fraud score
  /// 
  /// **Parameters:**
  /// - `userId`: User ID to analyze reviews for
  /// 
  /// **Returns:**
  /// ReviewFraudScore for user's reviews
  Future<ReviewFraudScore> analyzeUserReviews(String userId) async {
    try {
      _logger.info('Analyzing user reviews for fraud: user=$userId', tag: _logName);
      
      // In production, would get all feedback from user across all events
      // For now, using placeholder
      // TODO: Implement user review aggregation
      
      return ReviewFraudScore(
        id: 'review-fraud_${_uuid.v4()}',
        feedbackId: userId,
        riskScore: 0.0,
        signals: [],
        recommendation: FraudRecommendation.approve,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error analyzing user reviews for fraud', error: e, tag: _logName);
      rethrow;
    }
  }
  
  /// Get fraud score for reviews
  Future<ReviewFraudScore?> getFraudScore(String feedbackId) async {
    return _fraudScores[feedbackId];
  }
  
  // Private fraud signal detection methods
  
  /// Check if all reviews are 5-star
  bool _hasAllFiveStarReviews(List<EventFeedback> feedbacks) {
    if (feedbacks.length < 5) {
      return false; // Need at least 5 reviews for this to be suspicious
    }
    
    return feedbacks.every((f) => f.overallRating >= 4.9); // Allow slight variance
  }
  
  /// Check if reviews cluster on same day
  bool _hasSameDayClustering(List<EventFeedback> feedbacks) {
    if (feedbacks.length < 3) {
      return false; // Need at least 3 reviews
    }
    
    // Group by day
    final dayGroups = <DateTime, int>{};
    for (final feedback in feedbacks) {
      final day = DateTime(
        feedback.submittedAt.year,
        feedback.submittedAt.month,
        feedback.submittedAt.day,
      );
      dayGroups[day] = (dayGroups[day] ?? 0) + 1;
    }
    
    // Check if any single day has >= 50% of reviews
    final maxSameDay = dayGroups.values.reduce((a, b) => a > b ? a : b);
    return maxSameDay >= (feedbacks.length * 0.5).ceil();
  }
  
  /// Check if reviews are generic
  bool _hasGenericReviews(List<EventFeedback> feedbacks) {
    if (feedbacks.isEmpty) {
      return false;
    }
    
    // Generic phrases
    final genericPhrases = [
      'great',
      'good',
      'nice',
      'awesome',
      'amazing',
      'loved it',
      'had fun',
      'really enjoyed',
    ];
    
    int genericCount = 0;
    for (final feedback in feedbacks) {
      if (feedback.comments == null || feedback.comments!.isEmpty) {
        genericCount++;
        continue;
      }
      
      final comments = feedback.comments!.toLowerCase();
      
      // If comments are very short (< 20 chars), consider generic
      if (comments.length < 20) {
        genericCount++;
        continue;
      }
      
      // If comments contain multiple generic phrases, consider generic
      final phraseCount = genericPhrases.where((phrase) => comments.contains(phrase)).length;
      if (phraseCount >= 3) {
        genericCount++;
      }
    }
    
    // If >= 50% of reviews are generic, flag it
    return (genericCount / feedbacks.length) >= 0.5;
  }
  
  /// Check if reviews have similar language patterns
  bool _hasSimilarLanguage(List<EventFeedback> feedbacks) {
    if (feedbacks.length < 3) {
      return false;
    }
    
    // Simple similarity check: compare word overlap
    // In production, would use more sophisticated NLP
    final comments = feedbacks
        .where((f) => f.comments != null && f.comments!.isNotEmpty)
        .map((f) => f.comments!.toLowerCase().split(RegExp(r'\s+')))
        .toList();
    
    if (comments.length < 3) {
      return false;
    }
    
    // Check for high overlap between comments
    for (int i = 0; i < comments.length - 1; i++) {
      for (int j = i + 1; j < comments.length; j++) {
        final overlap = _calculateWordOverlap(comments[i], comments[j]);
        if (overlap > 0.7) {
          // High overlap suggests similar language
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Check if reviews appear coordinated
  bool _hasCoordinatedReviews(List<EventFeedback> feedbacks, List<FraudSignal> existingSignals) {
    // Coordinated reviews = combination of multiple suspicious signals
    final suspiciousSignals = existingSignals.where((s) => 
      s == FraudSignal.allFiveStar ||
      s == FraudSignal.sameDayClustering ||
      s == FraudSignal.similarLanguage
    ).length;
    
    // If 2+ suspicious signals present, likely coordinated
    return suspiciousSignals >= 2;
  }
  
  /// Calculate word overlap between two word lists
  double _calculateWordOverlap(List<String> words1, List<String> words2) {
    if (words1.isEmpty || words2.isEmpty) {
      return 0.0;
    }
    
    final set1 = words1.toSet();
    final set2 = words2.toSet();
    
    final intersection = set1.intersection(set2);
    final union = set1.union(set2);
    
    if (union.isEmpty) {
      return 0.0;
    }
    
    return intersection.length / union.length;
  }
  
  Future<void> _saveFraudScore(ReviewFraudScore score) async {
    // In production, save to database
    _fraudScores[score.feedbackId] = score;
  }
}

