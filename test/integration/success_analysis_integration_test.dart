import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_success_metrics.dart';
import 'package:spots/core/models/event_success_level.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/partner_rating.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for success analysis flow
/// 
/// Tests model relationships and data flow for:
/// 1. Event completion → Success metrics calculation
/// 2. Success factors identification
void main() {
  group('Success Analysis Integration Tests', () {
    late ExpertiseEvent testEvent;
    late List<EventFeedback> testFeedback;
    late List<PartnerRating> testPartnerRatings;

    setUp(() {
      final testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test Host',
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
        maxAttendees: 20,
        attendeeCount: 17,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      testFeedback = [
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
        EventFeedback(
          id: 'f3',
          eventId: testEvent.id,
          userId: 'u3',
          userRole: 'attendee',
          overallRating: 4.0,
          categoryRatings: const {},
          wouldRecommend: true,
          wouldAttendAgain: true,
          submittedAt: DateTime.now(),
        ),
      ];

      testPartnerRatings = [
        PartnerRating(
          id: 'r1',
          eventId: testEvent.id,
          partnershipId: 'p1',
          raterId: 'u1',
          ratedId: 'b1',
          partnershipRole: 'venue',
          overallRating: 4.5,
          professionalism: 5.0,
          communication: 4.5,
          reliability: 4.0,
          wouldPartnerAgain: 5.0,
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    test('success metrics calculated from event and feedback', () {
      final ticketsSold = testEvent.attendeeCount;
      final actualAttendance = ticketsSold; // Assuming all ticket holders attended
      final attendanceRate = actualAttendance / ticketsSold;

      final averageRating = testFeedback
              .map((f) => f.overallRating)
              .reduce((a, b) => a + b) /
          testFeedback.length;

      // Calculate NPS
      final promoters = testFeedback.where((f) => f.wouldRecommend).length;
      final detractors = testFeedback.where((f) => !f.wouldRecommend && f.overallRating < 3).length;
      final nps = ((promoters - detractors) / testFeedback.length * 100);

      // Calculate rating distribution
      final fiveStarCount = testFeedback.where((f) => f.overallRating >= 4.5 && f.overallRating <= 5.0).length;
      final fourStarCount = testFeedback.where((f) => f.overallRating >= 3.5 && f.overallRating < 4.5).length;
      final threeStarCount = testFeedback.where((f) => f.overallRating >= 2.5 && f.overallRating < 3.5).length;

      final metrics = EventSuccessMetrics(
        eventId: testEvent.id,
        ticketsSold: ticketsSold,
        actualAttendance: actualAttendance,
        attendanceRate: attendanceRate,
        grossRevenue: ticketsSold * (testEvent.price ?? 0.0),
        netRevenue: ticketsSold * (testEvent.price ?? 0.0) * 0.87, // After fees
        revenueVsProjected: 100.0,
        profitMargin: 0.87,
        averageRating: averageRating,
        nps: nps,
        fiveStarCount: fiveStarCount,
        fourStarCount: fourStarCount,
        threeStarCount: threeStarCount,
        twoStarCount: 0,
        oneStarCount: 0,
        feedbackResponseRate: (testFeedback.length / ticketsSold),
        attendeesWhoWouldReturn: testFeedback.where((f) => f.wouldAttendAgain).length,
        attendeesWhoWouldRecommend: testFeedback.where((f) => f.wouldRecommend).length,
        partnerSatisfaction: const {},
        partnersWouldCollaborateAgain: false,
        successLevel: EventSuccessLevel.high,
        successFactors: const [],
        improvementAreas: const [],
        calculatedAt: DateTime.now(),
      );

      expect(metrics.eventId, equals(testEvent.id));
      expect(metrics.attendanceRate, closeTo(1.0, 0.01));
      expect(metrics.averageRating, closeTo(4.5, 0.1));
      expect(metrics.attendeesWhoWouldRecommend, equals(3));
    });

    test('success level determined from metrics', () {
      final highSuccessMetrics = EventSuccessMetrics(
        eventId: testEvent.id,
        ticketsSold: 18,
        actualAttendance: 18,
        attendanceRate: 1.0,
        grossRevenue: 900.0,
        netRevenue: 783.0,
        revenueVsProjected: 100.0,
        profitMargin: 0.87,
        averageRating: 4.5,
        nps: 70.0,
        fiveStarCount: 10,
        fourStarCount: 5,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        feedbackResponseRate: 0.83,
        attendeesWhoWouldReturn: 15,
        attendeesWhoWouldRecommend: 15,
        partnerSatisfaction: const {},
        partnersWouldCollaborateAgain: true,
        successLevel: EventSuccessLevel.high,
        successFactors: const ['Great location', 'Engaging content'],
        improvementAreas: const [],
        calculatedAt: DateTime.now(),
      );

      expect(highSuccessMetrics.successLevel, equals(EventSuccessLevel.high));
      expect(highSuccessMetrics.attendanceRate, equals(1.0));
      expect(highSuccessMetrics.averageRating, equals(4.5));
    });

    test('success factors extracted from positive feedback', () {
      final feedbackWithHighlights = [
        EventFeedback(
          id: 'f1',
          eventId: testEvent.id,
          userId: 'u1',
          userRole: 'attendee',
          overallRating: 5.0,
          categoryRatings: const {},
          highlights: ['Great host', 'Excellent location', 'Engaging content'],
          wouldRecommend: true,
          wouldAttendAgain: true,
          submittedAt: DateTime.now(),
        ),
      ];

      final allHighlights = feedbackWithHighlights
          .where((f) => f.highlights != null)
          .expand((f) => f.highlights!)
          .toList();

      final successFactors = allHighlights.toSet().toList();

      final metrics = EventSuccessMetrics(
        eventId: testEvent.id,
        ticketsSold: 17,
        actualAttendance: 17,
        attendanceRate: 1.0,
        grossRevenue: 850.0,
        netRevenue: 739.5,
        revenueVsProjected: 100.0,
        profitMargin: 0.87,
        averageRating: 4.5,
        nps: 70.0,
        fiveStarCount: 3,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        feedbackResponseRate: 1.0,
        attendeesWhoWouldReturn: 17,
        attendeesWhoWouldRecommend: 17,
        partnerSatisfaction: const {},
        partnersWouldCollaborateAgain: false,
        successLevel: EventSuccessLevel.high,
        successFactors: successFactors,
        improvementAreas: const [],
        calculatedAt: DateTime.now(),
      );

      expect(metrics.successFactors.length, greaterThan(0));
      expect(metrics.successFactors, contains('Great host'));
    });

    test('improvement areas extracted from feedback', () {
      final feedbackWithImprovements = [
        EventFeedback(
          id: 'f1',
          eventId: testEvent.id,
          userId: 'u1',
          userRole: 'attendee',
          overallRating: 3.5,
          categoryRatings: const {},
          improvements: ['More breaks needed', 'Better communication'],
          wouldRecommend: true,
          wouldAttendAgain: true,
          submittedAt: DateTime.now(),
        ),
      ];

      final allImprovements = feedbackWithImprovements
          .where((f) => f.improvements != null)
          .expand((f) => f.improvements!)
          .toList();

      final improvementAreas = allImprovements.toSet().toList();

      final metrics = EventSuccessMetrics(
        eventId: testEvent.id,
        ticketsSold: 15,
        actualAttendance: 15,
        attendanceRate: 1.0,
        grossRevenue: 750.0,
        netRevenue: 652.5,
        revenueVsProjected: 100.0,
        profitMargin: 0.87,
        averageRating: 3.5,
        nps: 50.0,
        fiveStarCount: 0,
        fourStarCount: 1,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        feedbackResponseRate: 1.0,
        attendeesWhoWouldReturn: 10,
        attendeesWhoWouldRecommend: 10,
        partnerSatisfaction: const {},
        partnersWouldCollaborateAgain: false,
        successLevel: EventSuccessLevel.medium,
        successFactors: const [],
        improvementAreas: improvementAreas,
        calculatedAt: DateTime.now(),
      );

      expect(metrics.improvementAreas.length, greaterThan(0));
      expect(metrics.improvementAreas, contains('More breaks needed'));
      expect(metrics.successLevel, equals(EventSuccessLevel.medium));
    });

    test('partner ratings included in success metrics', () {
      final partnerSatisfaction = {
        for (var rating in testPartnerRatings)
          rating.ratedId: rating.overallRating
      };

      final partnersWouldCollaborateAgain = testPartnerRatings
          .every((r) => r.wouldPartnerAgain >= 4.0);

      final metrics = EventSuccessMetrics(
        eventId: testEvent.id,
        ticketsSold: 17,
        actualAttendance: 17,
        attendanceRate: 1.0,
        grossRevenue: 850.0,
        netRevenue: 739.5,
        revenueVsProjected: 100.0,
        profitMargin: 0.87,
        averageRating: 4.5,
        nps: 70.0,
        fiveStarCount: 3,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
        feedbackResponseRate: 1.0,
        attendeesWhoWouldReturn: 17,
        attendeesWhoWouldRecommend: 17,
        partnerSatisfaction: partnerSatisfaction,
        partnersWouldCollaborateAgain: partnersWouldCollaborateAgain,
        successLevel: EventSuccessLevel.high,
        successFactors: const [],
        improvementAreas: const [],
        calculatedAt: DateTime.now(),
      );

      expect(metrics.partnerSatisfaction, containsPair('b1', 4.5));
      expect(metrics.partnersWouldCollaborateAgain, isTrue);
    });
  });
}
