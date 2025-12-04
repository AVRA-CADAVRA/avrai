import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_partnership.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for feedback flow
/// 
/// Tests model relationships and data flow for:
/// 1. Feedback collection → Rating updates
/// 2. Partner ratings → Reputation updates
void main() {
  group('Feedback Flow Integration Tests', () {
    late ExpertiseEvent testEvent;
    late EventPartnership testPartnership;

    setUp(() {
      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
      );

      final testBusinessUser = ModelFactories.createTestUser(
        id: 'business-user-123',
        displayName: 'Business Owner',
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Workshop',
        description: 'Learn about coffee',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: testUser,
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().subtract(const Duration(hours: 23)),
        price: 50.0,
        isPaid: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      testPartnership = EventPartnership(
        id: 'partnership-123',
        eventId: testEvent.id,
        userId: testUser.id,
        businessId: 'business-456',
        status: PartnershipStatus.completed,
        type: PartnershipType.eventBased,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    });

    test('event feedback creates feedback record', () {
      final feedback = EventFeedback(
        id: 'feedback-123',
        eventId: testEvent.id,
        userId: 'attendee-456',
        userRole: 'attendee',
        overallRating: 4.5,
        categoryRatings: {
          'organization': 5.0,
          'content_quality': 4.5,
          'venue': 4.0,
        },
        comments: 'Great event!',
        highlights: ['Engaging host', 'Great location'],
        improvements: ['Could use more breaks'],
        wouldAttendAgain: true,
        wouldRecommend: true,
        submittedAt: DateTime.now(),
      );

      expect(feedback.eventId, equals(testEvent.id));
      expect(feedback.overallRating, equals(4.5));
      expect(feedback.overallRating, greaterThanOrEqualTo(4.0));
      expect(feedback.wouldAttendAgain, isTrue);
      expect(feedback.wouldRecommend, isTrue);
      expect(feedback.categoryRatings.length, equals(3));
    });

    test('partner rating creates rating record', () {
      final rating = PartnerRating(
        id: 'rating-123',
        eventId: testEvent.id,
        partnershipId: testPartnership.id,
        raterId: testPartnership.userId,
        ratedId: testPartnership.businessId,
        partnershipRole: 'venue',
        overallRating: 4.5,
        professionalism: 5.0,
        communication: 4.5,
        reliability: 4.0,
        wouldPartnerAgain: 5.0,
        positives: 'Great collaboration, easy to work with',
        improvements: 'More communication upfront would help',
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(rating.eventId, equals(testEvent.id));
      expect(rating.partnershipId, equals(testPartnership.id));
      expect(rating.overallRating, greaterThanOrEqualTo(4.0));
      expect(rating.wouldPartnerAgain, greaterThanOrEqualTo(4.0));
      expect(rating.professionalism, equals(5.0));
    });

    test('multiple feedback records aggregate correctly', () {
      final feedback1 = EventFeedback(
        id: 'feedback-1',
        eventId: testEvent.id,
        userId: 'attendee-1',
        userRole: 'attendee',
        overallRating: 5.0,
        categoryRatings: const {},
        wouldAttendAgain: true,
        wouldRecommend: true,
        submittedAt: DateTime.now(),
      );

      final feedback2 = EventFeedback(
        id: 'feedback-2',
        eventId: testEvent.id,
        userId: 'attendee-2',
        userRole: 'attendee',
        overallRating: 4.0,
        categoryRatings: const {},
        wouldAttendAgain: true,
        wouldRecommend: true,
        submittedAt: DateTime.now(),
      );

      final feedback3 = EventFeedback(
        id: 'feedback-3',
        eventId: testEvent.id,
        userId: 'attendee-3',
        userRole: 'attendee',
        overallRating: 4.5,
        categoryRatings: const {},
        wouldAttendAgain: true,
        wouldRecommend: true,
        submittedAt: DateTime.now(),
      );

      final allFeedback = [feedback1, feedback2, feedback3];
      final averageRating = allFeedback
              .map((f) => f.overallRating)
              .reduce((a, b) => a + b) /
          allFeedback.length;

      expect(averageRating, closeTo(4.5, 0.1));
      
      final positiveCount = allFeedback.where((f) => f.overallRating >= 4.0).length;
      expect(positiveCount, equals(3));
      
      final wouldRecommendCount = allFeedback.where((f) => f.wouldRecommend).length;
      expect(wouldRecommendCount, equals(3));
    });

    test('mutual partner ratings created for partnership', () {
      final rating1 = PartnerRating(
        id: 'rating-1',
        eventId: testEvent.id,
        partnershipId: testPartnership.id,
        raterId: testPartnership.userId,
        ratedId: testPartnership.businessId,
        partnershipRole: 'venue',
        overallRating: 4.5,
        professionalism: 5.0,
        communication: 4.5,
        reliability: 4.0,
        wouldPartnerAgain: 5.0,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final rating2 = PartnerRating(
        id: 'rating-2',
        eventId: testEvent.id,
        partnershipId: testPartnership.id,
        raterId: testPartnership.businessId,
        ratedId: testPartnership.userId,
        partnershipRole: 'host',
        overallRating: 4.5,
        professionalism: 5.0,
        communication: 4.0,
        reliability: 4.5,
        wouldPartnerAgain: 5.0,
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(rating1.partnershipId, equals(rating2.partnershipId));
      expect(rating1.raterId, equals(rating2.ratedId));
      expect(rating1.ratedId, equals(rating2.raterId));
      expect(rating1.overallRating, greaterThanOrEqualTo(4.0));
      expect(rating2.overallRating, greaterThanOrEqualTo(4.0));
    });

    test('feedback calculates NPS score', () {
      final promoters = [
        EventFeedback(
          id: 'f1',
          eventId: testEvent.id,
          userId: 'u1',
          userRole: 'attendee',
          overallRating: 5.0,
          categoryRatings: const {},
          wouldRecommend: true,
          wouldAttendAgain: true,
          submittedAt: DateTime.now(),
        ),
        EventFeedback(
          id: 'f2',
          eventId: testEvent.id,
          userId: 'u2',
          userRole: 'attendee',
          overallRating: 4.5,
          categoryRatings: const {},
          wouldRecommend: true,
          wouldAttendAgain: true,
          submittedAt: DateTime.now(),
        ),
      ];

      final detractors = [
        EventFeedback(
          id: 'f3',
          eventId: testEvent.id,
          userId: 'u3',
          userRole: 'attendee',
          overallRating: 2.0,
          categoryRatings: const {},
          wouldRecommend: false,
          wouldAttendAgain: false,
          submittedAt: DateTime.now(),
        ),
      ];

      final allFeedback = [...promoters, ...detractors];
      final total = allFeedback.length;
      final promoterCount = promoters.where((f) => f.wouldRecommend).length;
      final detractorCount = detractors.where((f) => !f.wouldRecommend && f.overallRating < 3).length;

      // NPS = (promoters - detractors) / total * 100
      final npsScore = ((promoterCount - detractorCount) / total * 100).round();

      expect(npsScore, equals(33)); // (2 - 1) / 3 * 100 = 33
    });
  });
}

