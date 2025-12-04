import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:spots/presentation/widgets/expertise/expertise_event_widget.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ExpertiseEventWidget
/// Tests expertise event display
void main() {
  group('ExpertiseEventWidget Widget Tests', () {
    testWidgets('displays event information', (WidgetTester tester) async {
      // Arrange
      final host = WidgetTestHelpers.createTestUser();
      final testDate = TestHelpers.createTestDateTime();
      final event = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Tasting Event',
        description: 'Join us for a coffee tasting',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: host,
        startTime: testDate.add(const Duration(days: 7)),
        endTime: testDate.add(const Duration(days: 7, hours: 2)),
        maxAttendees: 20,
        status: EventStatus.upcoming,
        attendeeIds: [],
        spots: [],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseEventWidget(event: event),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ExpertiseEventWidget), findsOneWidget);
      expect(find.text('Coffee Tasting Event'), findsOneWidget);
      expect(find.textContaining('Hosted by'), findsOneWidget);
    });

    testWidgets('displays register button when user can register', (WidgetTester tester) async {
      // Arrange
      final host = WidgetTestHelpers.createTestUser();
      final currentUser = WidgetTestHelpers.createTestUser(id: 'user-456');
      final testDate = TestHelpers.createTestDateTime();
      final event = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Tasting',
        description: 'Join us',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: host,
        startTime: testDate.add(const Duration(days: 7)),
        endTime: testDate.add(const Duration(days: 7, hours: 2)),
        maxAttendees: 20,
        status: EventStatus.upcoming,
        attendeeIds: [],
        spots: [],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseEventWidget(
          event: event,
          currentUser: currentUser,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Register'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('displays cancel button when user is registered', (WidgetTester tester) async {
      // Arrange
      final host = WidgetTestHelpers.createTestUser();
      final currentUser = WidgetTestHelpers.createTestUser(id: 'user-456');
      final testDate = TestHelpers.createTestDateTime();
      final event = ExpertiseEvent(
        id: 'event-123',
        title: 'Coffee Tasting',
        description: 'Join us',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: host,
        startTime: testDate.add(const Duration(days: 7)),
        endTime: testDate.add(const Duration(days: 7, hours: 2)),
        maxAttendees: 20,
        status: EventStatus.upcoming,
        attendeeIds: ['user-456'],
        spots: [],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseEventWidget(
          event: event,
          currentUser: currentUser,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Cancel Registration'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays event list widget', (WidgetTester tester) async {
      // Arrange
      final host = WidgetTestHelpers.createTestUser();
      final testDate = TestHelpers.createTestDateTime();
      final events = [
        ExpertiseEvent(
          id: 'event-1',
          title: 'Event 1',
          description: 'Description 1',
          category: 'Coffee',
          eventType: ExpertiseEventType.workshop,
          host: host,
          startTime: testDate.add(const Duration(days: 7)),
          endTime: testDate.add(const Duration(days: 7, hours: 2)),
          maxAttendees: 20,
          status: EventStatus.upcoming,
          attendeeIds: [],
          spots: [],
          createdAt: testDate,
          updatedAt: testDate,
        ),
      ];

      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertiseEventListWidget(events: events),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ExpertiseEventListWidget), findsOneWidget);
      expect(find.text('Event 1'), findsOneWidget);
    });

    testWidgets('displays empty state when no events', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertiseEventListWidget(events: []),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('No events found'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });
  });
}

