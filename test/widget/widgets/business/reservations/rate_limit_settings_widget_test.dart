// Rate Limit Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for RateLimitSettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/rate_limit_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('RateLimitSettingsWidget', () {
    late GetItTestHarness getIt;

    setUpAll(() async {
      await setupTestStorage();
      getIt = GetItTestHarness(sl: GetIt.instance);

      // Register StorageService in GetIt
      if (!GetIt.instance.isRegistered<StorageService>()) {
        getIt.registerSingletonReplace<StorageService>(StorageService.instance);
      }
    });

    tearDownAll(() async {
      getIt.unregisterIfRegistered<StorageService>();
      await cleanupTestStorage();
    });

    setUp(() async {
      // Clear storage before each test
      await StorageService.instance.clear();
    });

    testWidgets('should render widget with default rate limits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateLimitSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Use Default Rate Limits'), findsOneWidget);
    });

    testWidgets('should toggle to custom rate limits',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateLimitSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap to disable defaults (enable custom)
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show custom limit inputs
      expect(find.text('Per-User Limits'), findsOneWidget);
      expect(find.text('Per-Location Limits'), findsOneWidget);
    });

    testWidgets('should save custom hourly limit',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateLimitSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable custom limits
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Enter hourly limit
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      await tester.enterText(textFields.first, '20');
      await tester.pumpAndSettle();

      // Verify setting was saved
      final savedValue = StorageService.instance
          .getInt('reservation_rate_limit_hourly_test_business');
      expect(savedValue, equals(20));
    });
  });
}