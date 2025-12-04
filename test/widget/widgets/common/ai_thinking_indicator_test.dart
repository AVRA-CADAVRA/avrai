/// Tests for AI Thinking Indicator Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/ai_thinking_indicator.dart';

void main() {

  group('AIThinkingIndicator', () {
    testWidgets('renders full indicator with default stage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(),
          ),
        ),
      );

      await tester.pump();

      // Should show default stage title
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Crafting a personalized response'), findsOneWidget);
    });

    testWidgets('renders different stages correctly', (tester) async {
      for (final stage in AIThinkingStage.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AIThinkingIndicator(stage: stage),
            ),
          ),
        );

        await tester.pump();

        // Should show stage-specific title
        expect(find.byType(AIThinkingIndicator), findsOneWidget);
        
        // Verify icon is present
        expect(find.byIcon(_getIconForStage(stage)), findsOneWidget);
      }
    });

    testWidgets('renders compact indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              compact: true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Compact should show title but not description
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Crafting a personalized response'), findsNothing);
    });

    testWidgets('shows progress bar when showDetails is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              showDetails: true,
              stage: AIThinkingStage.analyzingPersonality,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Step 2 of 5'), findsOneWidget);
    });

    testWidgets('hides details when showDetails is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              showDetails: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should not show progress bar or description
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows timeout message after timeout duration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              timeout: const Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show normal indicator initially
      expect(find.text('AI is thinking...'), findsOneWidget);
      expect(find.text('Taking longer than usual'), findsNothing);

      // Wait for timeout
      await tester.pump(const Duration(milliseconds: 150));

      // Should show timeout message
      expect(find.text('Taking longer than usual'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('calls onTimeout callback when timeout occurs', (tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(
              timeout: const Duration(milliseconds: 100),
              onTimeout: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Wait for timeout
      await tester.pump(const Duration(milliseconds: 150));

      expect(callbackCalled, isTrue);
    });

    testWidgets('animation runs smoothly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingIndicator(),
          ),
        ),
      );

      // Pump a few frames to let animation run
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Indicator should still be present
      expect(find.byType(AIThinkingIndicator), findsOneWidget);
    });
  });

  group('AIThinkingDots', () {
    testWidgets('renders dots animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingDots(),
          ),
        ),
      );

      await tester.pump();

      // Should render the dots container
      expect(find.byType(AIThinkingDots), findsOneWidget);
    });

    testWidgets('animation runs for dots', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIThinkingDots(),
          ),
        ),
      );

      // Pump animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Dots should still be present
      expect(find.byType(AIThinkingDots), findsOneWidget);
    });
  });
}

/// Helper to get icon for stage
IconData _getIconForStage(AIThinkingStage stage) {
  switch (stage) {
    case AIThinkingStage.loadingContext:
      return Icons.inventory_2_outlined;
    case AIThinkingStage.analyzingPersonality:
      return Icons.psychology;
    case AIThinkingStage.consultingNetwork:
      return Icons.share;
    case AIThinkingStage.generatingResponse:
      return Icons.auto_awesome;
    case AIThinkingStage.finalizing:
      return Icons.check_circle_outline;
  }
}

