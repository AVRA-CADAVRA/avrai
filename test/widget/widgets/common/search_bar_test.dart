import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/search_bar.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for CustomSearchBar
/// Tests search bar UI, interactions, and callbacks
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('CustomSearchBar Widget Tests', () {
    testWidgets('displays search bar with default hint', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify search bar is present
      expect(find.text('Search...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(hintText: 'Search spots...'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show custom hint
      expect(find.text('Search spots...'), findsOneWidget);
    });

    testWidgets('displays initial value', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(initialValue: 'test query'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show initial value
      expect(find.text('test query'), findsOneWidget);
    });

    testWidgets('calls onChanged callback when text changes', (WidgetTester tester) async {
      // Arrange
      String? changedValue;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: CustomSearchBar(
          onChanged: (value) => changedValue = value,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byType(TextField), 'new query');
      await tester.pump();

      // Assert - Callback should be called
      expect(changedValue, equals('new query'));
    });

    testWidgets('shows clear button when text is entered', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(showClearButton: true),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert - Clear button should be visible
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('respects enabled state', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const CustomSearchBar(enabled: false),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - TextField should be disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });
  });
}

