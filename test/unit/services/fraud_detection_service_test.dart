import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/fraud_detection_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/fraud_score.dart';
import 'package:spots/core/models/fraud_recommendation.dart';
import 'package:spots/core/models/unified_user.dart';

import 'fraud_detection_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('FraudDetectionService', () {
    late FraudDetectionService service;
    late MockExpertiseEventService mockEventService;
    
    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      service = FraudDetectionService(eventService: mockEventService);

      testEvent = ExpertiseEvent(
        id: 'event-123',
        host: UnifiedUser(
          id: 'host-123',
          name: 'Test Host',
        ),
        title: 'Test Event',
        description: 'Test Description',
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
        maxAttendees: 50,
        attendeeCount: 10,
        eventType: ExpertiseEventType.workshop,
        isPaid: true,
        price: 25.00,
        location: 'Test Location',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('analyzeEvent', () {
      test('should analyze event and return fraud score', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final fraudScore = await service.analyzeEvent('event-123');

        // Assert
        expect(fraudScore, isA<FraudScore>());
        expect(fraudScore.eventId, equals('event-123'));
        expect(fraudScore.riskScore, greaterThanOrEqualTo(0.0));
        expect(fraudScore.riskScore, lessThanOrEqualTo(1.0));
        expect(fraudScore.recommendation, isA<FraudRecommendation>());
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.analyzeEvent('event-123'),
          throwsException,
        );
      });

      test('should detect fraud signals for suspicious event', () async {
        // Arrange
        final suspiciousEvent = testEvent.copyWith(
          price: 500.00, // Expensive event
          description: 'Great event', // Generic description
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => suspiciousEvent);

        // Act
        final fraudScore = await service.analyzeEvent('event-123');

        // Assert
        expect(fraudScore.signals, isNotEmpty);
        expect(fraudScore.riskScore, greaterThan(0.0));
      });
    });

    group('getFraudScore', () {
      test('should return fraud score if exists', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.analyzeEvent('event-123');

        // Act
        final score = await service.getFraudScore('event-123');

        // Assert
        expect(score, isNotNull);
        expect(score?.eventId, equals('event-123'));
      });

      test('should return null if fraud score not found', () async {
        // Act
        final score = await service.getFraudScore('non-existent');

        // Assert
        expect(score, isNull);
      });
    });

    group('getScoresNeedingReview', () {
      test('should return scores requiring review', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.analyzeEvent('event-123');

        // Act
        final scores = await service.getScoresNeedingReview();

        // Assert
        expect(scores, isA<List<FraudScore>>());
        // Scores requiring review should have high risk or multiple signals
      });
    });
  });
}

