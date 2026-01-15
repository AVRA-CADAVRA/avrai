// Time Slot Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for TimeSlotSettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/time_slot_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('TimeSlotSettingsWidget', () {
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

    testWidgets('should render widget with default settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeSlotSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Time Slot Interval'), findsOneWidget);
      expect(find.text('Default Slot Duration'), findsOneWidget);
    });

    testWidgets('should render widget with interval options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TimeSlotSettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders with interval options
      expect(find.text('Time Slot Interval'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets); // Should have filter chips for intervals
    });
  });
}