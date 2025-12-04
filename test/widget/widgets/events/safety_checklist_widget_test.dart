import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/safety_checklist_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';
import '../../../helpers/integration_test_helpers.dart';

/// Widget tests for SafetyChecklistWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('SafetyChecklistWidget Widget Tests', () {
    testWidgets('displays safety checklist widget', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);
    });

    testWidgets('displays with acknowledgment checkbox', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);
      bool acknowledged = false;

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event,
          showAcknowledgment: true,
          onAcknowledged: (value) {
            acknowledged = value;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);
    });

    testWidgets('displays in read-only mode', (WidgetTester tester) async {
      // Arrange
      final host = ModelFactories.createTestUser();
      final event = IntegrationTestHelpers.createTestEvent(host: host);

      final widget = WidgetTestHelpers.createTestableWidget(
        child: SafetyChecklistWidget(
          event: event,
          readOnly: true,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(SafetyChecklistWidget), findsOneWidget);
    });
  });
}

