// Notification History Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.3: Business Reservation Notifications
//
// Widget tests for NotificationHistoryWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/widgets/business/reservations/notification_history_widget.dart';
import 'package:avrai/core/services/supabase_service.dart';
import '../../../../helpers/platform_channel_helper.dart';
import '../../../../helpers/getit_test_harness.dart';

void main() {
  group('NotificationHistoryWidget', () {
    late GetItTestHarness getIt;

    setUpAll(() async {
      await setupTestStorage();
      getIt = GetItTestHarness(sl: GetIt.instance);

      // Register SupabaseService in GetIt
      if (!GetIt.instance.isRegistered<SupabaseService>()) {
        getIt.registerSingletonReplace<SupabaseService>(SupabaseService());
      }
    });

    tearDownAll(() async {
      getIt.unregisterIfRegistered<SupabaseService>();
      await cleanupTestStorage();
    });

    testWidgets('should render widget with empty state when offline',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationHistoryWidget(businessId: 'test_business'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that widget renders with empty state (Supabase offline by default)
      expect(find.text('No notifications yet'), findsOneWidget);
    });
  });
}
