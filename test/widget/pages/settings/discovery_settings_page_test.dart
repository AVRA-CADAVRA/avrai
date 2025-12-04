/// Tests for Discovery Settings Page
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/settings/discovery_settings_page.dart';

void main() {

  group('DiscoverySettingsPage', () {
    testWidgets('page renders with all sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show title
      expect(find.text('Discovery Settings'), findsOneWidget);
      
      // Should show main toggle
      expect(find.text('Enable Discovery'), findsOneWidget);
      
      // Should show header section
      expect(find.text('Device Discovery'), findsOneWidget);
      expect(find.text('Find nearby SPOTS-enabled devices'), findsOneWidget);
    });

    testWidgets('shows discovery methods when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enable discovery
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Should show discovery methods
      expect(find.text('Discovery Methods'), findsOneWidget);
      expect(find.text('WiFi Direct'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.text('Multipeer'), findsOneWidget);
    });

    testWidgets('shows privacy settings when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enable discovery
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Should show privacy settings
      expect(find.text('Privacy Settings'), findsOneWidget);
      expect(find.text('Share Personality Data'), findsOneWidget);
      expect(find.text('Privacy Information'), findsOneWidget);
    });

    testWidgets('shows advanced settings when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enable discovery
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Should show advanced settings
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Auto-Discovery'), findsOneWidget);
    });

    testWidgets('shows info section at bottom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Should show info section
      expect(find.text('About Discovery'), findsOneWidget);
      expect(find.textContaining('Discovery uses device radios'), findsOneWidget);
    });

    testWidgets('privacy info dialog can be opened', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Enable discovery to reveal privacy section
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Tap on Privacy Information
      await tester.tap(find.text('Privacy Information'));
      await tester.pumpAndSettle();

      // Should show dialog
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Anonymization'), findsOneWidget);
      expect(find.text('Encryption'), findsOneWidget);
    });

    testWidgets('discovery toggle persists state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DiscoverySettingsPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the main toggle switch
      final mainToggle = find.byType(SwitchListTile).first;

      // Should start as off
      SwitchListTile toggle = tester.widget(mainToggle);
      expect(toggle.value, isFalse);

      // Toggle it on
      await tester.tap(mainToggle);
      await tester.pumpAndSettle();

      // Should be on
      toggle = tester.widget(mainToggle);
      expect(toggle.value, isTrue);
    });
  });
}

