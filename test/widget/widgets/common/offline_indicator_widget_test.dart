/// Tests for Offline Indicator Widget
/// 
/// Part of Feature Matrix Phase 1.3: LLM Full Integration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/common/offline_indicator_widget.dart';

void main() {

  group('OfflineIndicatorWidget', () {
    testWidgets('shows indicator when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(isOffline: true),
          ),
        ),
      );

      expect(find.text('Limited Functionality'), findsOneWidget);
      expect(find.text('You\'re offline. Some features are unavailable.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('hides indicator when online', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(isOffline: false),
          ),
        ),
      );

      expect(find.text('Limited Functionality'), findsNothing);
    });

    testWidgets('expands to show feature details when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(isOffline: true),
          ),
        ),
      );

      // Initially collapsed
      expect(find.text('Not Available Offline'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Limited Functionality'));
      await tester.pumpAndSettle();

      // Should show expanded content
      expect(find.text('Not Available Offline'), findsOneWidget);
      expect(find.text('Still Works Offline'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              isOffline: true,
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      // Should show retry button
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tap retry
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });

    testWidgets('can be dismissed when showDismiss is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              isOffline: true,
              showDismiss: true,
            ),
          ),
        ),
      );

      // Should show dismiss button
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap dismiss
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Indicator should be gone
      expect(find.text('Limited Functionality'), findsNothing);
    });

    testWidgets('displays custom features when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineIndicatorWidget(
              isOffline: true,
              limitedFeatures: ['Feature A', 'Feature B'],
              availableFeatures: ['Feature C'],
            ),
          ),
        ),
      );

      // Expand
      await tester.tap(find.text('Limited Functionality'));
      await tester.pumpAndSettle();

      // Should show custom features
      expect(find.textContaining('Feature A'), findsOneWidget);
      expect(find.textContaining('Feature B'), findsOneWidget);
      expect(find.textContaining('Feature C'), findsOneWidget);
    });
  });

  group('OfflineBanner', () {
    testWidgets('shows banner when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(isOffline: true),
          ),
        ),
      );

      expect(find.text('Offline mode • Limited functionality'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('hides banner when online', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(isOffline: false),
          ),
        ),
      );

      expect(find.text('Offline mode • Limited functionality'), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              isOffline: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Tap banner
      await tester.tap(find.text('Offline mode • Limited functionality'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('AutoOfflineIndicator', () {
    testWidgets('builds with builder function', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoOfflineIndicator(
              builder: (context, isOffline) {
                return Text(isOffline ? 'Offline' : 'Online');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render something (actual connectivity depends on test environment)
      expect(find.byType(Text), findsOneWidget);
    });
  });
}

