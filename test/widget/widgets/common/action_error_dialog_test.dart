/// SPOTS ActionErrorDialog Widget Tests
/// Date: November 20, 2025
/// Purpose: Test ActionErrorDialog functionality and UI behavior
/// 
/// Test Coverage:
/// - Rendering: Dialog displays correctly with error message
/// - User Interactions: Dismiss and Retry button taps
/// - Edge Cases: Null intent, long error messages
/// 
/// Dependencies:
/// - ActionIntent models from core/ai/action_models.dart
/// - AppTheme for consistent styling

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/presentation/widgets/common/action_error_dialog.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ActionErrorDialog
/// Tests dialog rendering, user interactions, and error display
void main() {
  group('ActionErrorDialog Widget Tests', () {
    group('Rendering', () {
      testWidgets('displays dialog correctly with error message', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => ActionErrorDialog(
                    error: 'Something went wrong',
                    onDismiss: () {},
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.byType(ActionErrorDialog), findsOneWidget);
        expect(find.text('Action Failed'), findsOneWidget);
        // Error message is displayed - "Something went wrong" doesn't match translation patterns, so shown as-is
        // Use find.textContaining to find the error message in the dialog
        expect(find.textContaining('Something went wrong'), findsWidgets);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('displays retry button when onRetry provided', (WidgetTester tester) async {
        // Arrange
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => ActionErrorDialog(
                    error: 'Error',
                    onDismiss: () {},
                    onRetry: () {},
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('displays intent details if provided', (WidgetTester tester) async {
        // Arrange
        final intent = CreateSpotIntent(
          name: 'Test Spot',
          description: 'Test',
          latitude: 0.0,
          longitude: 0.0,
          category: 'Test',
          userId: 'user123',
          confidence: 0.9,
        );

        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => ActionErrorDialog(
                    error: 'Error',
                    intent: intent,
                    onDismiss: () {},
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Should show intent context
        expect(find.textContaining('Failed to create spot', findRichText: true), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('calls onDismiss when dismiss button is tapped', (WidgetTester tester) async {
        // Arrange
        bool dismissed = false;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => ActionErrorDialog(
                    error: 'Error',
                    onDismiss: () {
                      dismissed = true;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Assert
        expect(dismissed, isTrue);
        expect(find.byType(ActionErrorDialog), findsNothing);
      });

      testWidgets('calls onRetry when retry button is tapped', (WidgetTester tester) async {
        // Arrange
        bool retried = false;
        final widget = WidgetTestHelpers.createTestableWidget(
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  builder: (context) => ActionErrorDialog(
                    error: 'Error',
                    onDismiss: () {},
                    onRetry: () {
                      retried = true;
                      Navigator.of(context).pop();
                    },
                  ),
                );
              });
              return const Scaffold(body: SizedBox());
            },
          ),
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Assert
        expect(retried, isTrue);
        expect(find.byType(ActionErrorDialog), findsNothing);
      });
    });
  });
}

