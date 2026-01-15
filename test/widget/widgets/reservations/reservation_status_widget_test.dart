// Reservation Status Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for ReservationStatusWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_status_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ReservationStatusWidget
/// Tests reservation status badge display
void main() {
  group('ReservationStatusWidget Tests', () {
    testWidgets(
        'should display status badge correctly for all statuses in compact and full modes',
        (WidgetTester tester) async {
      // Test business logic: status badge display for all reservation statuses
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const ReservationStatusWidget(
          status: ReservationStatus.pending,
          compact: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.textContaining('PENDING'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const ReservationStatusWidget(
          status: ReservationStatus.confirmed,
          compact: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.textContaining('CONFIRMED'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const ReservationStatusWidget(
          status: ReservationStatus.cancelled,
          compact: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('CANCELLED'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });
}
