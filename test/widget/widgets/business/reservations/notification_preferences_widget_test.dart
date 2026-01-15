// Notification Preferences Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.3: Business Reservation Notifications
//
// Widget tests for NotificationPreferencesWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/notification_preferences_widget.dart';
import 'package:avrai/core/services/storage_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('NotificationPreferencesWidget', () {
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

    testWidgets('should render widget with default preferences',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationPreferencesWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('New Reservations'), findsOneWidget);
    });

    testWidgets('should toggle new reservation notifications',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationPreferencesWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all switches
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Tap first switch (new reservations)
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // Verify setting was saved
      final savedValue = StorageService.instance
          .getBool('reservation_notification_new_reservation_test_business');
      expect(savedValue, isFalse);
    });
  });
}
