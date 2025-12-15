import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/review_fraud_detection_service.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/review_fraud_score.dart';
import 'package:spots/core/models/fraud_signal.dart';

import 'review_fraud_detection_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([PostEventFeedbackService])
void main() {
  group('ReviewFraudDetectionService', () {
    late ReviewFraudDetectionService service;
    late MockPostEventFeedbackService mockFeedbackService;

    setUp(() {
      mockFeedbackService = MockPostEventFeedbackService();
      service = ReviewFraudDetectionService(feedbackService: mockFeedbackService);
    });

    group('analyzeReviews', () {
      test('should return low-risk score if no reviews', () async {
        // Arrange
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final fraudScore = await service.analyzeReviews('event-123');

        // Assert
        expect(fraudScore, isA<ReviewFraudScore>());
        expect(fraudScore.riskScore, equals(0.0));
        expect(fraudScore.signals, isEmpty);
      });

      test('should detect all 5-star reviews signal', () async {
        // Arrange
        // Service logic requires at least 5 reviews before "all five-star" is considered suspicious.
        final feedbacks = [
          EventFeedback(
            id: 'feedback-1',
            eventId: 'event-123',
            userId: 'user-1',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-2',
            eventId: 'event-123',
            userId: 'user-2',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-3',
            eventId: 'event-123',
            userId: 'user-3',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-4',
            eventId: 'event-123',
            userId: 'user-4',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-5',
            eventId: 'event-123',
            userId: 'user-5',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
        ];
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => feedbacks);

        // Act
        final fraudScore = await service.analyzeReviews('event-123');

        // Assert
        expect(fraudScore.signals, contains(FraudSignal.allFiveStar));
        expect(fraudScore.riskScore, greaterThan(0.0));
      });

      test('should detect same-day clustering signal', () async {
        // Arrange
        final now = DateTime.now();
        final feedbacks = [
          EventFeedback(
            id: 'feedback-1',
            eventId: 'event-123',
            userId: 'user-1',
            userRole: 'attendee',
            overallRating: 4.0,
            categoryRatings: {'quality': 4.0},
            submittedAt: now,
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-2',
            eventId: 'event-123',
            userId: 'user-2',
            userRole: 'attendee',
            overallRating: 4.5,
            categoryRatings: {'quality': 4.5},
            submittedAt: now.add(const Duration(hours: 1)),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
          EventFeedback(
            id: 'feedback-3',
            eventId: 'event-123',
            userId: 'user-3',
            userRole: 'attendee',
            overallRating: 5.0,
            categoryRatings: {'quality': 5.0},
            submittedAt: now.add(const Duration(hours: 2)),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
        ];
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => feedbacks);

        // Act
        final fraudScore = await service.analyzeReviews('event-123');

        // Assert
        expect(fraudScore.signals, contains(FraudSignal.sameDayClustering));
        expect(fraudScore.riskScore, greaterThan(0.0));
      });
    });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
  });
}

