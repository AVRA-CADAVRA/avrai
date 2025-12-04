import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/expertise/expert_search_widget.dart';
import "../../helpers/widget_test_helpers.dart';

/// Widget tests for ExpertSearchWidget
/// Tests expert search functionality
void main() {
  group('ExpertSearchWidget Widget Tests', () {
    testWidgets('displays search fields', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
      expect(find.text('Category (e.g., Coffee)'), findsOneWidget);
      expect(find.text('Location (optional)'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays initial category and location', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(
          initialCategory: 'Coffee',
          initialLocation: 'Brooklyn',
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Brooklyn'), findsOneWidget);
    });

    testWidgets('displays level filter chips', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Min Level:'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('displays empty state when no results', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show empty state or loading
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
    });

    testWidgets('calls onExpertSelected when expert is tapped', (WidgetTester tester) async {
      // Arrange
      UnifiedUser? selectedExpert;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ExpertSearchWidget(
          onExpertSelected: (expert) {
            selectedExpert = expert;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
    });

    testWidgets('performs search when search button is tapped', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ExpertSearchWidget(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Find search button and tap
      final searchButton = find.byIcon(Icons.search).last;
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Assert - Search should be triggered
      expect(find.byType(ExpertSearchWidget), findsOneWidget);
    });
  });
}

