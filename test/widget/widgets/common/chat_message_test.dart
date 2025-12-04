import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/chat_message.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

/// Widget tests for ChatMessage
/// Tests chat message display for user and AI messages
void main() {
  group('ChatMessage Widget Tests', () {
    testWidgets('displays user message correctly', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Hello, AI!',
          isUser: true,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ChatMessage), findsOneWidget);
      expect(find.text('Hello, AI!'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsNothing);
    });

    testWidgets('displays AI message correctly', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Hello! How can I help you?',
          isUser: false,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(ChatMessage), findsOneWidget);
      expect(find.text('Hello! How can I help you?'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('displays timestamp for user message', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Test message',
          isUser: true,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Timestamp should be displayed
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('displays timestamp for AI message', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'AI response',
          isUser: false,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Timestamp should be displayed
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('displays "Just now" for recent messages', (WidgetTester tester) async {
      // Arrange
      final recentTimestamp = DateTime.now();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'Recent message',
          isUser: true,
          timestamp: recentTimestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('aligns user message to the right', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'User message',
          isUser: true,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - User messages should be right-aligned
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));
    });

    testWidgets('aligns AI message to the left', (WidgetTester tester) async {
      // Arrange
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: 'AI message',
          isUser: false,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - AI messages should be left-aligned
      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.start));
    });

    testWidgets('handles long messages correctly', (WidgetTester tester) async {
      // Arrange
      final longMessage = 'This is a very long message that should wrap correctly '
          'and display properly in the chat interface without breaking the layout.';
      final timestamp = TestHelpers.createTestDateTime();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: ChatMessage(
          message: longMessage,
          isUser: true,
          timestamp: timestamp,
        ),
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text(longMessage), findsOneWidget);
    });
  });
}

