// Availability Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for AvailabilitySettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/availability_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('AvailabilitySettingsWidget', () {
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

    testWidgets('should render widget with default business hours',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AvailabilitySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Accept Reservations'), findsOneWidget);
      expect(find.text('Business Hours'), findsOneWidget);
    });

    testWidgets('should toggle reservations enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AvailabilitySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the switch
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Tap first switch (availability toggle)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Verify setting was saved
      final savedValue = StorageService.instance
          .getBool('reservation_availability_available_test_business');
      expect(savedValue, isNotNull);
    });
  });
}