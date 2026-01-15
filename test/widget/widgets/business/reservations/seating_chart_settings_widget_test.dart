// Seating Chart Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for SeatingChartSettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/seating_chart_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('SeatingChartSettingsWidget', () {
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

    testWidgets('should render widget with seating charts disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatingChartSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Enable Seating Charts'), findsOneWidget);
    });

    testWidgets('should toggle seating charts enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SeatingChartSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap to enable
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify setting was saved
      final savedValue = StorageService.instance
          .getBool('reservation_seating_chart_enabled_test_business');
      expect(savedValue, isTrue);
    });
  });
}