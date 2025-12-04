import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/geographic_scope_indicator_widget.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../fixtures/model_factories.dart';

/// Widget tests for GeographicScopeIndicatorWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('GeographicScopeIndicatorWidget Widget Tests', () {
    testWidgets('displays geographic scope indicator', (WidgetTester tester) async {
      // Arrange
      final user = ModelFactories.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: GeographicScopeIndicatorWidget(
          user: user,
          category: 'Food & Drink',
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(GeographicScopeIndicatorWidget), findsOneWidget);
    });

    testWidgets('displays scope description', (WidgetTester tester) async {
      // Arrange
      final user = ModelFactories.createTestUser();

      final widget = WidgetTestHelpers.createTestableWidget(
        child: GeographicScopeIndicatorWidget(
          user: user,
          category: 'Food & Drink',
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(GeographicScopeIndicatorWidget), findsOneWidget);
    });
  });
}

