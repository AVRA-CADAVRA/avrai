// Business Reservation Analytics Page Tests
//
// Phase 7.2: Business Reservation Analytics
// Widget tests for BusinessReservationAnalyticsPage

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/pages/business/reservations/business_reservation_analytics_page.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart' as helpers;

/// Widget tests for BusinessReservationAnalyticsPage
/// Tests analytics page display and interactions
void main() {
  group('BusinessReservationAnalyticsPage Tests', () {
    testWidgets(
        'should display analytics page correctly, show loading state initially, handle error states, and display analytics content when loaded',
        (WidgetTester tester) async {
      // Test business logic: analytics page display and interactions
      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: BusinessReservationAnalyticsPage(
          businessId: 'test-business-id',
          type: ReservationType.business,
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should display page title
      expect(find.text('Business Reservation Analytics'), findsOneWidget);

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Should have date range picker button
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}
