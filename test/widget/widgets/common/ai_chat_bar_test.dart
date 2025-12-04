import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/ai_chat_bar.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for AIChatBar
/// Tests AI chat input bar functionality
void main() {
  group('AIChatBar Widget Tests', () {
    testWidgets('displays chat bar with default hint text', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(AIChatBar), findsOneWidget);
      expect(find.text('Ask AI about spots, recommendations...'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('displays custom hint text', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(hintText: 'Custom hint text'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Custom hint text'), findsOneWidget);
    });

    testWidgets('displays initial value', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(initialValue: 'Initial message'),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Initial message'), findsOneWidget);
    });

    testWidgets('calls onSendMessage when send button is tapped', (WidgetTester tester) async {
      // Arrange
      String? sentMessage;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AIChatBar(
          onSendMessage: (message) {
            sentMessage = message;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Enter text
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pumpAndSettle();
      
      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert
      expect(sentMessage, equals('Test message'));
    });

    testWidgets('calls onSendMessage when enter is pressed', (WidgetTester tester) async {
      // Arrange
      String? sentMessage;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AIChatBar(
          onSendMessage: (message) {
            sentMessage = message;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      
      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Assert
      expect(sentMessage, equals('Test message'));
    });

    testWidgets('disables send button when text is empty', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Send button should be disabled (null onPressed)
      final sendButton = tester.widget<IconButton>(find.byIcon(Icons.send));
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('enables send button when text is entered', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - Send button should be enabled
      final sendButton = tester.widget<IconButton>(find.byIcon(Icons.send));
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(isLoading: true),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('disables input when enabled is false', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(enabled: false),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('calls onTap when text field is tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AIChatBar(
          onTap: () {
            tapped = true;
          },
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('clears text after sending message', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const AIChatBar(),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Assert - Text field should be cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}

