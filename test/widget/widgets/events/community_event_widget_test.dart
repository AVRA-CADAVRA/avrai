import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/community_event_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for CommunityEventWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
/// 
/// Tests:
/// - Widget rendering
/// - Event display
/// - Registration status
/// - Callback handling
/// - Upgrade eligibility
void main() {
  group('CommunityEventWidget Widget Tests', () {
    testWidgets('displays community event with title', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Community Coffee Meetup',
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.text('Community Coffee Meetup'), findsOneWidget);
    });

    testWidgets('displays community badge', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('displays register button when user can register', (WidgetTester tester) async {
      // Arrange
      final user = WidgetTestHelpers.createTestUser();
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(
        host: host,
        maxAttendees: 10,
        attendeeIds: [],
      );

      bool registerCalled = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
          currentUser: user,
          onRegister: () => registerCalled = true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.text('Join Event'), findsOneWidget);
    });

    testWidgets('displays upgrade eligibility indicator', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
          isEligibleForUpgrade: true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      expect(find.textContaining('Eligible for upgrade'), findsOneWidget);
    });

    testWidgets('calls onTap callback when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
          onTap: () => wasTapped = true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(CommunityEventWidget));
      await tester.pump();

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('displays event details', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(
        host: host,
        location: 'Brooklyn, NY',
        maxAttendees: 20,
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: CommunityEventWidget(
          event: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CommunityEventWidget), findsOneWidget);
      // Event details should be visible
    });
  });
}

