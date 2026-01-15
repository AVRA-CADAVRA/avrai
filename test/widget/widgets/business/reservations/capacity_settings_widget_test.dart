// Capacity Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for CapacitySettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/capacity_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('CapacitySettingsWidget', () {
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
            body: SingleChildScrollView(
              child: CapacitySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders (check for key elements that are unique)
      expect(find.text('Total Capacity'), findsWidgets); // May appear multiple times
      expect(find.byType(Switch), findsOneWidget); // Should have one switch
    });

    testWidgets('should toggle unlimited capacity',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CapacitySettingsWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap to enable limited capacity
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Should show capacity input field
      expect(find.byType(TextField), findsWidgets); // May have multiple text fields
    });

    testWidgets('should save max party size setting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CapacitySettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find max party size input
      final textFields = find.byType(TextField);
      expect(textFields, findsOneWidget);

      // Enter value
      await tester.enterText(textFields.first, '10');
      await tester.pumpAndSettle();

      // Verify setting was saved (check storage)
      final savedValue =
          StorageService.instance.getInt('reservation_capacity_max_party_test_business');
      expect(savedValue, equals(10));
    });
  });
}