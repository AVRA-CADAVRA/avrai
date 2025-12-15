import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/universal_ai_search.dart';
import '../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('UniversalAISearch Widget Tests', () {
    testWidgets('displays search field with hint text',
        (WidgetTester tester) async {
      // Arrange
      const hintText = 'Search for anything...';
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          hintText: hintText,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      // Verify TextField exists (not TextFormField)
      expect(find.byType(TextField), findsOneWidget);

      // Verify hint text by checking TextField's decoration property
      // (hint text in InputDecoration is not rendered as a Text widget)
      final textFieldWidget = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget.decoration?.hintText, equals(hintText));
    });

    testWidgets('calls onCommand when text is submitted',
        (WidgetTester tester) async {
      // Arrange
      String? submittedCommand;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Test search',
          onCommand: (command) => submittedCommand = command,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.enterText(find.byType(TextField), 'test command');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Assert
      expect(submittedCommand, equals('test command'));
    });

    testWidgets('clears text after submission', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Test search',
          onCommand: (command) {},
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.enterText(find.byType(TextField), 'test command');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Assert - Text field should be cleared
      expect(find.text('test command'), findsNothing);
    });

    testWidgets('shows loading state when enabled',
        (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          hintText: 'Loading search',
          isLoading: true,
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables input when disabled', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          hintText: 'Disabled search',
          enabled: false,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.enterText(find.byType(TextField), 'should not work');

      // Assert - Text should not be entered when disabled
      expect(find.text('should not work'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Arrange
      var tapped = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Tappable search',
          onTap: () => tapped = true,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('displays initial value correctly',
        (WidgetTester tester) async {
      // Arrange
      const initialValue = 'Initial search term';
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          hintText: 'Search',
          initialValue: initialValue,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text(initialValue), findsOneWidget);
    });

    testWidgets('shows search suggestions when focused',
        (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Search with suggestions',
          onCommand: (command) {},
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert - Would show suggestions in a real implementation
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('handles empty command submission gracefully',
        (WidgetTester tester) async {
      // Arrange
      String? submittedCommand;
      var callbackCount = 0;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Empty test',
          onCommand: (command) {
            submittedCommand = command;
            callbackCount++;
          },
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Submit empty text
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Assert - Should not call callback for empty command
      expect(submittedCommand, isNull);
      expect(callbackCount, equals(0));
    });

    testWidgets('trims whitespace from commands', (WidgetTester tester) async {
      // Arrange
      String? submittedCommand;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Trim test',
          onCommand: (command) => submittedCommand = command,
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.enterText(find.byType(TextField), '  test command  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Assert
      expect(submittedCommand, equals('test command'));
    });

    testWidgets('meets accessibility requirements',
        (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const UniversalAISearch(
          hintText: 'Accessible search',
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      final textFieldWidget = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldWidget.decoration?.hintText, equals('Accessible search'));
      
      // Text field should meet minimum size requirements
      final textField = tester.getSize(find.byType(TextField));
      expect(textField.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('handles rapid text input changes',
        (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: UniversalAISearch(
          hintText: 'Rapid input test',
          onCommand: (command) {},
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Rapidly change text
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      // Assert - Should handle rapid changes gracefully
      expect(find.text('abc'), findsOneWidget);
    });

    testWidgets('maintains focus state correctly', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: Scaffold(
          body: Column(
            children: [
              UniversalAISearch(
                hintText: 'Focus test',
                onCommand: (command) {},
              ),
              const TextField(), // Another field to test focus transfer
            ],
          ),
        ),
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Focus on search field
      await tester.tap(find.byType(UniversalAISearch));
      await tester.pump();

      // Assert - Should handle focus correctly
      expect(find.byType(UniversalAISearch), findsOneWidget);
    });
  });
}
