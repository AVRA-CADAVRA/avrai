/// Tests for Discovery Settings Page
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/storage_service.dart';
import 'package:spots/presentation/pages/settings/discovery_settings_page.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('DiscoverySettingsPage', () {
    setUp(() async {
      // Ensure tests don't leak persisted state via StorageService
      await StorageService.instance.setBool('discovery_enabled', false);
    });

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
      final mainToggleFinder = find.byType(SwitchListTile).first;
      final mainToggle = tester.widget<SwitchListTile>(mainToggleFinder);
      if (mainToggle.value == false) {
        await tester.tap(mainToggleFinder);
        await tester.pumpAndSettle();
      }

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
      final mainToggleFinder = find.byType(SwitchListTile).first;
      final mainToggle = tester.widget<SwitchListTile>(mainToggleFinder);
      if (mainToggle.value == false) {
        await tester.tap(mainToggleFinder);
        await tester.pumpAndSettle();
      }

      // Scroll to privacy section (ListView builds lazily)
      for (var i = 0; i < 6 && find.text('Privacy Settings').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();
      }

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
      final mainToggleFinder = find.byType(SwitchListTile).first;
      final mainToggle = tester.widget<SwitchListTile>(mainToggleFinder);
      if (mainToggle.value == false) {
        await tester.tap(mainToggleFinder);
        await tester.pumpAndSettle();
      }

      // Scroll to advanced section (ListView builds lazily)
      for (var i = 0; i < 6 && find.text('Advanced').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pumpAndSettle();
      }

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

      // Scroll to info section at bottom (ListView builds lazily)
      for (var i = 0; i < 10 && find.text('About Discovery').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }

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
      final mainToggleFinder = find.byType(SwitchListTile).first;
      final mainToggle = tester.widget<SwitchListTile>(mainToggleFinder);
      if (mainToggle.value == false) {
        await tester.tap(mainToggleFinder);
        await tester.pumpAndSettle();
      }

      // Ensure Privacy Information ListTile is visible (ListView builds lazily)
      final privacyInfoFinder = find.text('Privacy Information');
      await tester.ensureVisible(privacyInfoFinder);
      await tester.pumpAndSettle();

      // Tap on Privacy Information ListTile (not just the text)
      final privacyInfoTile = find.ancestor(
        of: privacyInfoFinder,
        matching: find.byType(ListTile),
      );
      await tester.tap(privacyInfoTile, warnIfMissed: false);
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

