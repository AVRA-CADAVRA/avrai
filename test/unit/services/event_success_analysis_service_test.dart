import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/event_success_analysis_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_success_metrics.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'event_success_analysis_service_test.mocks.dart';

@GenerateMocks([
  ExpertiseEventService,
  PostEventFeedbackService,
  PaymentService,
])
void main() {
  group('EventSuccessAnalysisService', () {
    late EventSuccessAnalysisService service;
    late MockExpertiseEventService mockEventService;
    late MockPostEventFeedbackService mockFeedbackService;
    late MockPaymentService mockPaymentService;
    
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;
    late List<EventFeedback> testFeedbacks;
    late List<PartnerRating> testPartnerRatings;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockFeedbackService = MockPostEventFeedbackService();
      mockPaymentService = MockPaymentService();
      
      service = EventSuccessAnalysisService(
        eventService: mockEventService,
        feedbackService: mockFeedbackService,
        paymentService: mockPaymentService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().subtract(const Duration(days: 1, hours: -2)),
        maxAttendees: 50,
        attendeeCount: 40,
        isPaid: true,
        price: 25.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      testFeedbacks = [
        EventFeedback(
          id: 'feedback-1',
          eventId: 'event-123',
          userId: 'user-456',
          userRole: 'attendee',
          overallRating: 5.0,
          categoryRatings: {'organization': 5.0, 'content': 5.0},
          comments: 'Amazing event!',
          highlights: ['Great venue', 'Excellent content'],
          improvements: [],
          submittedAt: DateTime.now(),
          wouldAttendAgain: true,
          wouldRecommend: true,
        ),
        EventFeedback(
          id: 'feedback-2',
          eventId: 'event-123',
          userId: 'user-789',
          userRole: 'attendee',
          overallRating: 4.0,
          categoryRatings: {'organization': 4.0, 'content': 4.0},
          comments: 'Good event',
          highlights: ['Nice atmosphere'],
          improvements: ['Could use more time'],
          submittedAt: DateTime.now(),
          wouldAttendAgain: true,
          wouldRecommend: true,
        ),
        EventFeedback(
          id: 'feedback-3',
          eventId: 'event-123',
          userId: 'user-101',
          userRole: 'attendee',
          overallRating: 3.0,
          categoryRatings: {'organization': 3.0, 'content': 3.0},
          comments: 'It was okay',
          highlights: [],
          improvements: ['Needs improvement'],
          submittedAt: DateTime.now(),
          wouldAttendAgain: false,
          wouldRecommend: false,
        ),
      ];

      testPartnerRatings = [
        PartnerRating(
          id: 'rating-1',
          eventId: 'event-123',
          raterId: 'user-123',
          ratedId: 'business-123',
          partnershipRole: 'business',
          overallRating: 4.5,
          professionalism: 5.0,
          communication: 4.0,
          reliability: 4.5,
          wouldPartnerAgain: 4.0,
          positives: 'Great communication',
          improvements: 'Could be more responsive',
          submittedAt: DateTime.now(),
        ),
      ];
    });

    group('analyzeEventSuccess', () {
      test('should analyze event success with feedback successfully', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => testPartnerRatings);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics, isA<EventSuccessMetrics>());
        expect(metrics.eventId, equals('event-123'));
        expect(metrics.ticketsSold, equals(40));
        expect(metrics.averageRating, closeTo(4.0, 0.1));
        expect(metrics.successLevel, isA<EventSuccessLevel>());
        expect(metrics.successFactors, isNotEmpty);
        expect(metrics.improvementAreas, isNotEmpty);
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockFeedbackService.getFeedbackForEvent('event-123')).called(1);
        verify(mockFeedbackService.getPartnerRatingsForEvent('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.analyzeEventSuccess('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });

      test('should handle event with no feedback', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => []);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics, isA<EventSuccessMetrics>());
        expect(metrics.averageRating, equals(0.0));
        expect(metrics.fiveStarCount, equals(0));
        expect(metrics.fourStarCount, equals(0));
        expect(metrics.threeStarCount, equals(0));
      });

      test('should calculate attendance metrics correctly', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.ticketsSold, equals(40));
        expect(metrics.actualAttendance, greaterThan(0));
        expect(metrics.attendanceRate, greaterThan(0));
        expect(metrics.attendanceRate, lessThanOrEqualTo(1.0));
      });

      test('should calculate financial metrics correctly', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.grossRevenue, equals(1000.0)); // 40 * 25
        expect(metrics.netRevenue, greaterThan(0));
        expect(metrics.netRevenue, lessThan(metrics.grossRevenue));
        expect(metrics.profitMargin, greaterThan(0));
      });

      test('should calculate quality metrics correctly', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.averageRating, closeTo(4.0, 0.1)); // (5.0 + 4.0 + 3.0) / 3
        expect(metrics.fiveStarCount, equals(1));
        expect(metrics.fourStarCount, equals(1));
        expect(metrics.threeStarCount, equals(1));
        expect(metrics.attendeesWhoWouldReturn, equals(2)); // 2 would attend again
        expect(metrics.attendeesWhoWouldRecommend, equals(2)); // 2 would recommend
      });

      test('should calculate NPS correctly', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        // Promoters: 2 (would recommend + rating >= 4)
        // Detractors: 1 (would not recommend OR rating <= 2)
        // NPS = ((2 - 1) / 3) * 100 = 33.33
        expect(metrics.nps, greaterThan(0));
      });

      test('should determine success level based on metrics', () async {
        // Arrange
        final successfulEvent = testEvent.copyWith(
          attendeeCount: 45, // 90% attendance
        );
        final highRatingFeedbacks = [
          EventFeedback(
            id: 'feedback-1',
            eventId: 'event-123',
            userId: 'user-456',
            userRole: 'attendee',
            overallRating: 4.8,
            submittedAt: DateTime.now(),
            wouldAttendAgain: true,
            wouldRecommend: true,
          ),
        ];
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => successfulEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => highRatingFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.successLevel, isA<EventSuccessLevel>());
      });

      test('should identify success factors from feedback', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.successFactors, isNotEmpty);
        expect(metrics.successFactors.any((f) => f.contains('High attendance') || f.contains('Excellent ratings') || f.contains('Great venue') || f.contains('Excellent content')), isTrue);
      });

      test('should identify improvement areas from feedback', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.improvementAreas, isNotEmpty);
        expect(metrics.improvementAreas.any((a) => a.contains('Needs improvement') || a.contains('Could use more time')), isTrue);
      });

      test('should include partner satisfaction scores', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => []);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => testPartnerRatings);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.partnerSatisfaction, isNotEmpty);
        expect(metrics.partnerSatisfaction.containsKey('business-123'), isTrue);
        expect(metrics.partnersWouldCollaborateAgain, isA<bool>());
      });

      test('should handle free events (no financial metrics)', () async {
        // Arrange
        final freeEvent = testEvent.copyWith(
          isPaid: false,
          price: null,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => freeEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await service.analyzeEventSuccess('event-123');

        // Assert
        expect(metrics.grossRevenue, equals(0.0));
        expect(metrics.netRevenue, equals(0.0));
      });
    });

    group('getEventMetrics', () {
      test('should return null if metrics not found', () async {
        // Act
        final metrics = await service.getEventMetrics('event-123');

        // Assert
        expect(metrics, isNull);
      });

      test('should return metrics after analysis', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockFeedbackService.getFeedbackForEvent('event-123'))
            .thenAnswer((_) async => testFeedbacks);
        when(mockFeedbackService.getPartnerRatingsForEvent('event-123'))
            .thenAnswer((_) async => []);
        await service.analyzeEventSuccess('event-123');

        // Act
        final metrics = await service.getEventMetrics('event-123');

        // Assert
        expect(metrics, isNotNull);
        expect(metrics!.eventId, equals('event-123'));
      });
    });
  });
}

