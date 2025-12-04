import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/models/event_partnership.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'post_event_feedback_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService, PartnershipService])
void main() {
  group('PostEventFeedbackService', () {
    late PostEventFeedbackService service;
    late MockExpertiseEventService mockEventService;
    late MockPartnershipService mockPartnershipService;
    
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockPartnershipService = MockPartnershipService();
      
      service = PostEventFeedbackService(
        eventService: mockEventService,
        partnershipService: mockPartnershipService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attendeeIds: ['user-456', 'user-789'],
      );
    });

    group('scheduleFeedbackCollection', () {
      test('should schedule feedback collection 2 hours after event ends', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final scheduledTime = await service.scheduleFeedbackCollection('event-123');

        // Assert
        expect(scheduledTime, isA<DateTime>());
        expect(scheduledTime, equals(testEvent.endTime.add(const Duration(hours: 2))));
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.scheduleFeedbackCollection('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });
    });

    group('sendFeedbackRequests', () {
      test('should send feedback requests to all attendees', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => []);

        // Act
        await service.sendFeedbackRequests('event-123');

        // Assert
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockPartnershipService.getPartnershipsForEvent('event-123')).called(1);
      });

      test('should send partner rating requests when partnerships exist', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockPartnershipService.getPartnershipsForEvent('event-123'))
            .thenAnswer((_) async => [
              EventPartnership(
                id: 'partnership-123',
                eventId: 'event-123',
                userId: 'user-123',
                businessId: 'business-123',
                status: PartnershipStatus.locked,
                vibeCompatibilityScore: 0.75,
                userApproved: true,
                businessApproved: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]);

        // Act
        await service.sendFeedbackRequests('event-123');

        // Assert
        verify(mockEventService.getEventById('event-123')).called(1);
        verify(mockPartnershipService.getPartnershipsForEvent('event-123')).called(1);
      });
    });

    group('submitFeedback', () {
      test('should create and save feedback successfully', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final feedback = await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 4.5,
          categoryRatings: {'organization': 4.5, 'content_quality': 5.0},
          comments: 'Great event!',
          highlights: ['Great venue', 'Excellent content'],
          improvements: ['Could use more time'],
          wouldAttendAgain: true,
          wouldRecommend: true,
        );

        // Assert
        expect(feedback, isA<EventFeedback>());
        expect(feedback.eventId, equals('event-123'));
        expect(feedback.userId, equals('user-456'));
        expect(feedback.overallRating, equals(4.5));
        expect(feedback.categoryRatings['organization'], equals(4.5));
        expect(feedback.categoryRatings['content_quality'], equals(5.0));
        expect(feedback.comments, equals('Great event!'));
        expect(feedback.highlights, equals(['Great venue', 'Excellent content']));
        expect(feedback.improvements, equals(['Could use more time']));
        expect(feedback.wouldAttendAgain, isTrue);
        expect(feedback.wouldRecommend, isTrue);
        expect(feedback.submittedAt, isA<DateTime>());
      });

      test('should create feedback with minimal required fields', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final feedback = await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 3.0,
          wouldAttendAgain: false,
          wouldRecommend: false,
        );

        // Assert
        expect(feedback, isA<EventFeedback>());
        expect(feedback.overallRating, equals(3.0));
        expect(feedback.categoryRatings, isEmpty);
        expect(feedback.comments, isNull);
        expect(feedback.highlights, isNull);
        expect(feedback.improvements, isNull);
        expect(feedback.wouldAttendAgain, isFalse);
        expect(feedback.wouldRecommend, isFalse);
      });
    });

    group('submitPartnerRating', () {
      test('should create and save partner rating successfully', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final rating = await service.submitPartnerRating(
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
        );

        // Assert
        expect(rating, isA<PartnerRating>());
        expect(rating.eventId, equals('event-123'));
        expect(rating.raterId, equals('user-123'));
        expect(rating.ratedId, equals('business-123'));
        expect(rating.partnershipRole, equals('business'));
        expect(rating.overallRating, equals(4.5));
        expect(rating.professionalism, equals(5.0));
        expect(rating.communication, equals(4.0));
        expect(rating.reliability, equals(4.5));
        expect(rating.wouldPartnerAgain, equals(4.0));
        expect(rating.positives, equals('Great communication'));
        expect(rating.improvements, equals('Could be more responsive'));
        expect(rating.submittedAt, isA<DateTime>());
      });

      test('should create partner rating with minimal required fields', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final rating = await service.submitPartnerRating(
          eventId: 'event-123',
          raterId: 'user-123',
          ratedId: 'business-123',
          partnershipRole: 'business',
          overallRating: 3.0,
          professionalism: 3.0,
          communication: 3.0,
          reliability: 3.0,
          wouldPartnerAgain: 3.0,
        );

        // Assert
        expect(rating, isA<PartnerRating>());
        expect(rating.overallRating, equals(3.0));
        expect(rating.positives, isNull);
        expect(rating.improvements, isNull);
      });
    });

    group('getFeedbackForEvent', () {
      test('should return empty list when no feedback exists', () async {
        // Act
        final feedbacks = await service.getFeedbackForEvent('event-123');

        // Assert
        expect(feedbacks, isEmpty);
      });

      test('should return feedback for event after submission', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        await service.submitFeedback(
          eventId: 'event-123',
          userId: 'user-456',
          overallRating: 4.5,
          wouldAttendAgain: true,
          wouldRecommend: true,
        );

        final feedbacks = await service.getFeedbackForEvent('event-123');

        // Assert
        expect(feedbacks, hasLength(1));
        expect(feedbacks.first.userId, equals('user-456'));
      });
    });

    group('getPartnerRatingsForEvent', () {
      test('should return empty list when no ratings exist', () async {
        // Act
        final ratings = await service.getPartnerRatingsForEvent('event-123');

        // Assert
        expect(ratings, isEmpty);
      });

      test('should return partner ratings for event after submission', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        await service.submitPartnerRating(
          eventId: 'event-123',
          raterId: 'user-123',
          ratedId: 'business-123',
          partnershipRole: 'business',
          overallRating: 4.5,
          professionalism: 5.0,
          communication: 4.0,
          reliability: 4.5,
          wouldPartnerAgain: 4.0,
        );

        final ratings = await service.getPartnerRatingsForEvent('event-123');

        // Assert
        expect(ratings, hasLength(1));
        expect(ratings.first.raterId, equals('user-123'));
        expect(ratings.first.ratedId, equals('business-123'));
      });
    });
  });
}

