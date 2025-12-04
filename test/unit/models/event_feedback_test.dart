import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/event_feedback.dart';

/// SPOTS EventFeedback Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventFeedback model functionality
/// 
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Rating Validation: Overall and category ratings
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
/// 
/// Dependencies:
/// - PartnerRating: Partner rating model (in same file)

void main() {
  group('EventFeedback', () {
    late EventFeedback feedback;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      feedback = EventFeedback(
        id: 'feedback-123',
        eventId: 'event-456',
        userId: 'user-789',
        userRole: 'attendee',
        overallRating: 4.5,
        categoryRatings: {
          'organization': 4.5,
          'content_quality': 5.0,
          'venue': 4.0,
        },
        comments: 'Great event!',
        highlights: ['Great organization', 'Interesting content'],
        improvements: ['Better venue', 'More time'],
        submittedAt: testDate,
        wouldAttendAgain: true,
        wouldRecommend: true,
      );
    });

    group('Constructor and Properties', () {
      test('should create feedback with all required fields', () {
        expect(feedback.id, 'feedback-123');
        expect(feedback.eventId, 'event-456');
        expect(feedback.userId, 'user-789');
        expect(feedback.userRole, 'attendee');
        expect(feedback.overallRating, 4.5);
        expect(feedback.categoryRatings.length, 3);
        expect(feedback.comments, 'Great event!');
        expect(feedback.highlights, ['Great organization', 'Interesting content']);
        expect(feedback.improvements, ['Better venue', 'More time']);
        expect(feedback.wouldAttendAgain, true);
        expect(feedback.wouldRecommend, true);
      });

      test('should create feedback with minimal fields', () {
        final minimalFeedback = EventFeedback(
          id: 'feedback-1',
          eventId: 'event-1',
          userId: 'user-1',
          userRole: 'attendee',
          overallRating: 3.0,
          categoryRatings: {'overall': 3.0},
          submittedAt: testDate,
          wouldAttendAgain: false,
          wouldRecommend: false,
        );

        expect(minimalFeedback.comments, isNull);
        expect(minimalFeedback.highlights, isNull);
        expect(minimalFeedback.improvements, isNull);
        expect(minimalFeedback.metadata, isEmpty);
      });
    });

    group('Rating Validation', () {
      test('should accept valid ratings', () {
        expect(feedback.overallRating, greaterThanOrEqualTo(1.0));
        expect(feedback.overallRating, lessThanOrEqualTo(5.0));
        
        for (final rating in feedback.categoryRatings.values) {
          expect(rating, greaterThanOrEqualTo(1.0));
          expect(rating, lessThanOrEqualTo(5.0));
        }
      });

      test('should handle multiple category ratings', () {
        final detailedFeedback = feedback.copyWith(
          categoryRatings: {
            'organization': 4.5,
            'content_quality': 5.0,
            'venue': 4.0,
            'value_for_money': 4.5,
            'communication': 5.0,
          },
        );

        expect(detailedFeedback.categoryRatings.length, 5);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = feedback.toJson();

        expect(json['id'], 'feedback-123');
        expect(json['eventId'], 'event-456');
        expect(json['userId'], 'user-789');
        expect(json['userRole'], 'attendee');
        expect(json['overallRating'], 4.5);
        expect(json['categoryRatings'], isA<Map>());
        expect(json['comments'], 'Great event!');
        expect(json['highlights'], ['Great organization', 'Interesting content']);
        expect(json['improvements'], ['Better venue', 'More time']);
        expect(json['wouldAttendAgain'], true);
        expect(json['wouldRecommend'], true);
      });

      test('should deserialize from JSON correctly', () {
        final json = feedback.toJson();
        final deserialized = EventFeedback.fromJson(json);

        expect(deserialized.id, feedback.id);
        expect(deserialized.eventId, feedback.eventId);
        expect(deserialized.userId, feedback.userId);
        expect(deserialized.userRole, feedback.userRole);
        expect(deserialized.overallRating, feedback.overallRating);
        expect(deserialized.categoryRatings, feedback.categoryRatings);
        expect(deserialized.comments, feedback.comments);
        expect(deserialized.highlights, feedback.highlights);
        expect(deserialized.improvements, feedback.improvements);
        expect(deserialized.wouldAttendAgain, feedback.wouldAttendAgain);
        expect(deserialized.wouldRecommend, feedback.wouldRecommend);
      });

      test('should handle null optional fields in JSON', () {
        final minimalFeedback = EventFeedback(
          id: 'feedback-1',
          eventId: 'event-1',
          userId: 'user-1',
          userRole: 'attendee',
          overallRating: 3.0,
          categoryRatings: {'overall': 3.0},
          submittedAt: testDate,
          wouldAttendAgain: false,
          wouldRecommend: false,
        );
        final json = minimalFeedback.toJson();
        final deserialized = EventFeedback.fromJson(json);

        expect(deserialized.comments, isNull);
        expect(deserialized.highlights, isNull);
        expect(deserialized.improvements, isNull);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final feedback2 = feedback.copyWith();
        expect(feedback, equals(feedback2));
      });

      test('should not be equal when properties differ', () {
        final feedback2 = feedback.copyWith(overallRating: 3.0);
        expect(feedback, isNot(equals(feedback2)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final updated = feedback.copyWith(
          overallRating: 5.0,
          wouldAttendAgain: false,
          comments: 'Updated comment',
        );

        expect(updated.overallRating, 5.0);
        expect(updated.wouldAttendAgain, false);
        expect(updated.comments, 'Updated comment');
        expect(updated.id, feedback.id); // Unchanged
      });

      test('should preserve all fields when copying', () {
        final copied = feedback.copyWith();
        expect(copied, equals(feedback));
      });
    });
  });

  group('PartnerRating', () {
    late PartnerRating rating;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);
      
      rating = PartnerRating(
        id: 'rating-123',
        eventId: 'event-456',
        raterId: 'user-789',
        ratedId: 'user-012',
        partnershipRole: 'host',
        overallRating: 4.5,
        professionalism: 5.0,
        communication: 4.0,
        reliability: 4.5,
        wouldPartnerAgain: 5.0,
        positives: 'Great communication',
        improvements: 'Could be more punctual',
        submittedAt: testDate,
      );
    });

    group('Constructor and Properties', () {
      test('should create rating with all required fields', () {
        expect(rating.id, 'rating-123');
        expect(rating.eventId, 'event-456');
        expect(rating.raterId, 'user-789');
        expect(rating.ratedId, 'user-012');
        expect(rating.partnershipRole, 'host');
        expect(rating.overallRating, 4.5);
        expect(rating.professionalism, 5.0);
        expect(rating.communication, 4.0);
        expect(rating.reliability, 4.5);
        expect(rating.wouldPartnerAgain, 5.0);
      });

      test('should create rating with optional fields', () {
        expect(rating.positives, 'Great communication');
        expect(rating.improvements, 'Could be more punctual');
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = rating.toJson();

        expect(json['id'], 'rating-123');
        expect(json['eventId'], 'event-456');
        expect(json['raterId'], 'user-789');
        expect(json['ratedId'], 'user-012');
        expect(json['partnershipRole'], 'host');
        expect(json['overallRating'], 4.5);
        expect(json['professionalism'], 5.0);
        expect(json['communication'], 4.0);
        expect(json['reliability'], 4.5);
        expect(json['wouldPartnerAgain'], 5.0);
      });

      test('should deserialize from JSON correctly', () {
        final json = rating.toJson();
        final deserialized = PartnerRating.fromJson(json);

        expect(deserialized.id, rating.id);
        expect(deserialized.eventId, rating.eventId);
        expect(deserialized.raterId, rating.raterId);
        expect(deserialized.ratedId, rating.ratedId);
        expect(deserialized.overallRating, rating.overallRating);
      });
    });
  });
}

