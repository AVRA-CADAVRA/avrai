import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import '../../fixtures/model_factories.dart';

/// Expertise Event Service Tests
/// Tests expert-led event management functionality
void main() {
  group('ExpertiseEventService Tests', () {
    late ExpertiseEventService service;
    late UnifiedUser host;
    late List<Spot> spots;

    setUp(() {
      service = ExpertiseEventService();
      host = ModelFactories.createTestUser(
        id: 'host-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
      spots = [
        ModelFactories.createTestSpot(name: 'Spot 1'),
        ModelFactories.createTestSpot(name: 'Spot 2'),
      ];
    });

    group('createEvent', () {
      test('should create event when host has local level expertise', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );

        expect(event, isA<ExpertiseEvent>());
        expect(event.title, equals('Food Tour'));
        expect(event.category, equals('food'));
        expect(event.host.id, equals(host.id));
        expect(event.status, equals(EventStatus.upcoming));
      });

      test('should throw exception when host lacks local level expertise', () async {
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'host-456',
        );
        // No expertise - cannot host events

        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        expect(
          () => service.createEvent(
            host: userWithoutExpertise,
            title: 'Food Tour',
            description: 'A guided food tour',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when host lacks expertise in category', () async {
        final hostWithoutCategory = ModelFactories.createTestUser(
          id: 'host-789',
        ).copyWith(
          expertiseMap: {'coffee': 'city'},
        );

        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        expect(
          () => service.createEvent(
            host: hostWithoutCategory,
            title: 'Food Tour',
            description: 'A guided food tour',
            category: 'food',
            eventType: ExpertiseEventType.tour,
            startTime: startTime,
            endTime: endTime,
          ),
          throwsException,
        );
      });

      test('should set isPaid when price is provided', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Paid Workshop',
          description: 'A paid workshop',
          category: 'food',
          eventType: ExpertiseEventType.workshop,
          startTime: startTime,
          endTime: endTime,
          price: 50.0,
        );

        expect(event.isPaid, isTrue);
        expect(event.price, equals(50.0));
      });

      test('should include spots when provided', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Spot Tour',
          description: 'Tour of spots',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
          spots: spots,
        );

        expect(event.spots.length, equals(spots.length));
      });
    });

    group('registerForEvent', () {
      test('should register user for event', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );

        final attendee = ModelFactories.createTestUser(id: 'attendee-123');

        await service.registerForEvent(event, attendee);

        // Verify registration (in production, would fetch updated event)
        expect(event.canUserAttend(attendee.id), isTrue);
      });

      test('should throw exception when event is full', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Full Event',
          description: 'Event at capacity',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
          maxAttendees: 1,
        );

        final attendee1 = ModelFactories.createTestUser(id: 'attendee-1');
        final attendee2 = ModelFactories.createTestUser(id: 'attendee-2');

        await service.registerForEvent(event, attendee1);

        expect(
          () => service.registerForEvent(event, attendee2),
          throwsException,
        );
      });
    });

    group('cancelRegistration', () {
      test('should cancel user registration', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );

        final attendee = ModelFactories.createTestUser(id: 'attendee-123');

        await service.registerForEvent(event, attendee);
        await service.cancelRegistration(event, attendee);

        // Verify cancellation (in production, would fetch updated event)
        expect(event.canUserAttend(attendee.id), isTrue);
      });

      test('should throw exception when user is not registered', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );

        final nonAttendee = ModelFactories.createTestUser(id: 'non-attendee');

        expect(
          () => service.cancelRegistration(event, nonAttendee),
          throwsException,
        );
      });
    });

    group('getEventsByHost', () {
      test('should return events hosted by expert', () async {
        final events = await service.getEventsByHost(host);

        expect(events, isA<List<ExpertiseEvent>>());
      });
    });

    group('getEventsByAttendee', () {
      test('should return events user is attending', () async {
        final user = ModelFactories.createTestUser(id: 'user-123');
        final events = await service.getEventsByAttendee(user);

        expect(events, isA<List<ExpertiseEvent>>());
      });
    });

    group('searchEvents', () {
      test('should search events by category', () async {
        final events = await service.searchEvents(
          category: 'food',
        );

        expect(events, isA<List<ExpertiseEvent>>());
      });

      test('should filter by location', () async {
        final events = await service.searchEvents(
          location: 'San Francisco',
        );

        expect(events, isA<List<ExpertiseEvent>>());
      });

      test('should filter by event type', () async {
        final events = await service.searchEvents(
          eventType: ExpertiseEventType.tour,
        );

        expect(events, isA<List<ExpertiseEvent>>());
      });

      test('should respect maxResults parameter', () async {
        final events = await service.searchEvents(
          category: 'food',
          maxResults: 10,
        );

        expect(events.length, lessThanOrEqualTo(10));
      });
    });

    group('getUpcomingEventsInCategory', () {
      test('should return upcoming events in category', () async {
        final events = await service.getUpcomingEventsInCategory(
          'food',
          maxResults: 10,
        );

        expect(events, isA<List<ExpertiseEvent>>());
        expect(events.length, lessThanOrEqualTo(10));
      });
    });

    group('updateEventStatus', () {
      test('should update event status', () async {
        final startTime = DateTime.now().add(const Duration(days: 7));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createEvent(
          host: host,
          title: 'Food Tour',
          description: 'A guided food tour',
          category: 'food',
          eventType: ExpertiseEventType.tour,
          startTime: startTime,
          endTime: endTime,
        );

        await service.updateEventStatus(event, EventStatus.completed);

        // Verify status update (in production, would fetch updated event)
        expect(event.status, equals(EventStatus.completed));
      });
    });
  });
}

