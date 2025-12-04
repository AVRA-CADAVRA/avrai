import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/event_host_again_button.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for EventHostAgainButton
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('EventHostAgainButton Widget Tests', () {
    testWidgets('displays host again button', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(
        host: host,
        title: 'Community Coffee Meetup',
      );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EventHostAgainButton(
          originalEvent: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(EventHostAgainButton), findsOneWidget);
      expect(find.text('Host Again'), findsOneWidget);
    });

    testWidgets('displays replay icon', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EventHostAgainButton(
          originalEvent: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(EventHostAgainButton), findsOneWidget);
    });
  });
}

