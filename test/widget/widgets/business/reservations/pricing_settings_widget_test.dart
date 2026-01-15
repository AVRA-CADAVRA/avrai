// Pricing Settings Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget tests for PricingSettingsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/pricing_settings_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('PricingSettingsWidget', () {
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

    testWidgets('should render widget with free pricing by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PricingSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Reservation Pricing'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('should toggle to paid reservations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PricingSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the pricing switch
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Tap first switch (pricing toggle)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Should show ticket price input
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Ticket Price (\$)'), findsOneWidget);
    });

    testWidgets('should save ticket price when entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PricingSettingsWidget(businessId: 'test_business'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enable paid pricing
      final switches = find.byType(Switch);
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Enter ticket price
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      await tester.enterText(textFields.first, '25.00');
      await tester.pumpAndSettle();

      // Verify setting was saved
      final savedValue = StorageService.instance
          .getDouble('reservation_pricing_price_test_business');
      expect(savedValue, equals(25.0));
    });
  });
}