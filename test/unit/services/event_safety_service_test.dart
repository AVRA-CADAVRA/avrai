import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/event_safety_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_safety_guidelines.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'event_safety_service_test.mocks.dart';

@GenerateMocks([ExpertiseEventService])
void main() {
  group('EventSafetyService', () {
    late EventSafetyService service;
    late MockExpertiseEventService mockEventService;
    
    late ExpertiseEvent testEvent;
    late UnifiedUser testUser;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      
      service = EventSafetyService(
        eventService: mockEventService,
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
        eventType: ExpertiseEventType.workshop,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        maxAttendees: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('generateGuidelines', () {
      test('should generate guidelines for event successfully', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final guidelines = await service.generateGuidelines('event-123');

        // Assert
        expect(guidelines, isA<EventSafetyGuidelines>());
        expect(guidelines.eventId, equals('event-123'));
        expect(guidelines.type, equals(ExpertiseEventType.workshop));
        expect(guidelines.requirements, isNotEmpty);
        expect(guidelines.acknowledged, isFalse);
        expect(guidelines.emergencyInfo, isNotNull);
        expect(guidelines.insurance, isNotNull);
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.generateGuidelines('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });

      test('should include workshop-specific requirements', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final guidelines = await service.generateGuidelines('event-123');

        // Assert
        expect(guidelines.requirements, contains(SafetyRequirement.firstAidKit));
        expect(guidelines.requirements, contains(SafetyRequirement.capacityLimit));
        expect(guidelines.requirements, contains(SafetyRequirement.emergencyExits));
      });

      test('should include tour-specific requirements', () async {
        // Arrange
        final tourEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tour,
          maxAttendees: 20,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tourEvent);

        // Act
        final guidelines = await service.generateGuidelines('event-123');

        // Assert
        expect(guidelines.requirements, contains(SafetyRequirement.weatherPlan));
        expect(guidelines.requirements, contains(SafetyRequirement.crowdControl));
      });

      test('should include tasting-specific requirements', () async {
        // Arrange
        final tastingEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tasting,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => tastingEvent);

        // Act
        final guidelines = await service.generateGuidelines('event-123');

        // Assert
        expect(guidelines.requirements, contains(SafetyRequirement.foodSafety));
        expect(guidelines.requirements, contains(SafetyRequirement.alcoholPolicy));
        expect(guidelines.requirements, contains(SafetyRequirement.firstAidKit));
      });

      test('should include requirements for large events (>50 attendees)', () async {
        // Arrange
        final largeEvent = testEvent.copyWith(
          maxAttendees: 75,
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => largeEvent);

        // Act
        final guidelines = await service.generateGuidelines('event-123');

        // Assert
        expect(guidelines.requirements, contains(SafetyRequirement.accessibilityPlan));
        expect(guidelines.requirements, contains(SafetyRequirement.crowdControl));
      });
    });

    group('getEmergencyInfo', () {
      test('should return emergency information for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final emergencyInfo = await service.getEmergencyInfo('event-123');

        // Assert
        expect(emergencyInfo, isNotNull);
        expect(emergencyInfo.primaryContact, isNotNull);
        expect(emergencyInfo.primaryContact.role, equals('Host'));
        expect(emergencyInfo.nearestHospital, isNotNull);
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should use provided event if passed', () async {
        // Act
        final emergencyInfo = await service.getEmergencyInfo('event-123', testEvent);

        // Assert
        expect(emergencyInfo, isNotNull);
        expect(emergencyInfo.primaryContact, isNotNull);
        verifyNever(mockEventService.getEventById(any));
      });

      test('should throw exception if event not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.getEmergencyInfo('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Event not found'),
          )),
        );
      });
    });

    group('getInsuranceRecommendation', () {
      test('should return insurance recommendation for event', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final recommendation = service.getInsuranceRecommendation(testEvent);

        // Assert
        expect(recommendation, isNotNull);
        expect(recommendation.estimatedCost, greaterThan(0));
        expect(recommendation.isRecommended, isA<bool>());
        expect(recommendation.coverageAmount, greaterThan(0));
      });

      test('should recommend insurance for large events', () async {
        // Arrange
        final largeEvent = testEvent.copyWith(maxAttendees: 100);

        // Act
        final recommendation = service.getInsuranceRecommendation(largeEvent);

        // Assert
        expect(recommendation.isRecommended, isTrue);
      });

      test('should recommend insurance for paid events', () async {
        // Arrange
        final paidEvent = testEvent.copyWith(
          isPaid: true,
          price: 50.0,
        );

        // Act
        final recommendation = service.getInsuranceRecommendation(paidEvent);

        // Assert
        expect(recommendation.isRecommended, isTrue);
      });
    });

    group('getGuidelines', () {
      test('should return existing guidelines if available', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.generateGuidelines('event-123');

        // Act
        final guidelines = await service.getGuidelines('event-123');

        // Assert
        expect(guidelines, isNotNull);
        expect(guidelines!.eventId, equals('event-123'));
        verify(mockEventService.getEventById('event-123')).called(1);
      });

      test('should generate guidelines if not available', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);

        // Act
        final guidelines = await service.getGuidelines('event-123');

        // Assert
        expect(guidelines, isNotNull);
        expect(guidelines!.eventId, equals('event-123'));
        verify(mockEventService.getEventById('event-123')).called(1);
      });
    });

    group('acknowledgeGuidelines', () {
      test('should acknowledge guidelines successfully', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        await service.generateGuidelines('event-123');

        // Act
        await service.acknowledgeGuidelines('event-123');

        // Assert
        final guidelines = await service.getGuidelines('event-123');
        expect(guidelines!.acknowledged, isTrue);
        expect(guidelines.acknowledgedAt, isNotNull);
      });

      test('should throw exception if guidelines not found', () async {
        // Arrange
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => service.acknowledgeGuidelines('event-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Guidelines not found'),
          )),
        );
      });
    });

    group('determineSafetyRequirements', () {
      test('should determine requirements for workshop event', () {
        // Act
        final requirements = service.determineSafetyRequirements(testEvent);

        // Assert
        expect(requirements, contains(SafetyRequirement.firstAidKit));
        expect(requirements, contains(SafetyRequirement.capacityLimit));
      });

      test('should determine requirements for tour event', () {
        // Arrange
        final tourEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tour,
          maxAttendees: 20,
        );

        // Act
        final requirements = service.determineSafetyRequirements(tourEvent);

        // Assert
        expect(requirements, contains(SafetyRequirement.weatherPlan));
      });

      test('should determine requirements for tasting event', () {
        // Arrange
        final tastingEvent = testEvent.copyWith(
          eventType: ExpertiseEventType.tasting,
        );

        // Act
        final requirements = service.determineSafetyRequirements(tastingEvent);

        // Assert
        expect(requirements, contains(SafetyRequirement.foodSafety));
        expect(requirements, contains(SafetyRequirement.alcoholPolicy));
      });
    });
  });
}
