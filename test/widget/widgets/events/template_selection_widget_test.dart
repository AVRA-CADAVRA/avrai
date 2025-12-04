import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/events/template_selection_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for TemplateSelectionWidget
/// 
/// Agent 2: Phase 7, Section 51-52 - Widget Test Coverage
void main() {
  group('TemplateSelectionWidget Widget Tests', () {
    testWidgets('displays template selection widget', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          onTemplateSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);
    });

    testWidgets('displays with selected category filter', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          selectedCategory: 'Food & Drink',
          onTemplateSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);
    });

    testWidgets('displays business templates when enabled', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: TemplateSelectionWidget(
          showBusinessTemplates: true,
          onTemplateSelected: (_) {},
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(TemplateSelectionWidget), findsOneWidget);
    });
  });
}

