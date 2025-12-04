/// Tests for Action Success Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/presentation/widgets/common/action_success_widget.dart';

void main() {

  group('ActionSuccessWidget', () {
    testWidgets('displays success dialog for CreateListIntent', (tester) async {
      final intent = CreateListIntent(
        title: 'Coffee Shops',
        description: 'Best coffee spots',
        userId: 'user-1',
        confidence: 0.9,
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'List created successfully',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Should show success elements
      expect(find.text('🎉 List Created!'), findsOneWidget);
      expect(find.text('Coffee Shops'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays success dialog for CreateSpotIntent', (tester) async {
      final intent = CreateSpotIntent(
        name: 'Blue Bottle Coffee',
        category: 'cafe',
        latitude: 37.7749,
        longitude: -122.4194,
        userId: 'user-1',
        confidence: 0.85,
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'Spot created successfully',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('📍 Spot Created!'), findsOneWidget);
      expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    });

    testWidgets('shows undo button with countdown', (tester) async {
      bool undoCalled = false;
      
      final intent = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'Created',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(
                      result: result,
                      onUndo: () {
                        undoCalled = true;
                      },
                      undoTimeout: const Duration(seconds: 5),
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Should show undo section
      expect(find.textContaining('Can undo in'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);

      // Tap undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undoCalled, isTrue);
    });

    testWidgets('calls onViewResult when View button tapped', (tester) async {
      bool viewCalled = false;
      
      final intent = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'Created',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(
                      result: result,
                      onViewResult: () {
                        viewCalled = true;
                      },
                    ),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Should show View button
      expect(find.text('View'), findsOneWidget);

      // Tap view
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(viewCalled, isTrue);
    });

    testWidgets('Done button closes dialog', (tester) async {
      final intent = CreateListIntent(
        title: 'Test List',
        description: '',
        userId: 'user-1',
        confidence: 0.9,
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'Created',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('🎉 List Created!'), findsOneWidget);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('🎉 List Created!'), findsNothing);
    });

    testWidgets('handles AddSpotToListIntent', (tester) async {
      final intent = AddSpotToListIntent(
        spotId: 'spot-1',
        listId: 'list-1',
        userId: 'user-1',
        confidence: 0.8,
        metadata: {
          'spotName': 'Blue Bottle',
          'listName': 'Coffee Shops',
        },
      );
      
      final result = ActionResult.success(
        intent: intent,
        message: 'Added to list',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ActionSuccessWidget(result: result),
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('✨ Added to List!'), findsOneWidget);
      expect(find.text('Blue Bottle'), findsOneWidget);
      expect(find.text('Coffee Shops'), findsOneWidget);
    });
  });

  group('ActionSuccessToast', () {
    testWidgets('renders toast with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSuccessToast(
              message: 'Action completed!',
            ),
          ),
        ),
      );

      expect(find.text('Action completed!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('renders with custom icon and color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionSuccessToast(
              message: 'Deleted!',
              icon: Icons.delete,
            ),
          ),
        ),
      );

      expect(find.text('Deleted!'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}

