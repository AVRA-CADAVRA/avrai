import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/event_scope_tab_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for EventScopeTabWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('EventScopeTabWidget Widget Tests', () {
    testWidgets('displays event scope tab widget', (WidgetTester tester) async {
      // Arrange
      bool tabChanged = false;
      EventScope? selectedScope;

      final widget = WidgetTestHelpers.createTestableWidget(
        child: EventScopeTabWidget(
          onTabChanged: (scope) {
            tabChanged = true;
            selectedScope = scope;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(EventScopeTabWidget), findsOneWidget);
    });

    testWidgets('displays with initial scope', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: EventScopeTabWidget(
          initialScope: EventScope.city,
          onTabChanged: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(EventScopeTabWidget), findsOneWidget);
    });
  });
}

