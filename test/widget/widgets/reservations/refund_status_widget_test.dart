// Refund Status Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for RefundStatusWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/refund_status_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for RefundStatusWidget
/// Tests refund status display
void main() {
  group('RefundStatusWidget Tests', () {
    testWidgets(
        'should display refund status correctly for cancelled reservations, show refund amount when eligible, show dispute status when applicable, or display no refund message when not eligible',
        (WidgetTester tester) async {
      // Test business logic: refund status display for cancelled reservations
      final now = DateTime.now();
      final cancelledReservation = Reservation(
        id: 'res-1',
        agentId: 'agent-1',
        type: ReservationType.spot,
        targetId: 'spot-123',
        reservationTime: now.add(const Duration(days: 7)),
        partySize: 2,
        status: ReservationStatus.cancelled,
        createdAt: now,
        updatedAt: now,
      );

      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: RefundStatusWidget(
          reservation: cancelledReservation,
          qualifiesForRefund: true,
          refundAmount: 100.0,
          refundIssued: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.textContaining('Refund Pending'), findsOneWidget);
      expect(find.textContaining('\$100.00'), findsOneWidget);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: RefundStatusWidget(
          reservation: cancelledReservation,
          qualifiesForRefund: false,
          refundAmount: null,
          refundIssued: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.textContaining('No Refund'), findsOneWidget);
      expect(find.textContaining('does not qualify for a refund'), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: RefundStatusWidget(
          reservation: cancelledReservation,
          qualifiesForRefund: true,
          refundAmount: 100.0,
          refundIssued: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('Refund Processed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      final disputedReservation = Reservation(
        id: 'res-2',
        agentId: 'agent-2',
        type: ReservationType.event,
        targetId: 'event-456',
        reservationTime: now.add(const Duration(days: 3)),
        partySize: 4,
        status: ReservationStatus.cancelled,
        disputeStatus: DisputeStatus.submitted,
        createdAt: now,
        updatedAt: now,
      );

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: RefundStatusWidget(
          reservation: disputedReservation,
          qualifiesForRefund: false,
          refundAmount: null,
          refundIssued: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.textContaining('Dispute Submitted'), findsOneWidget);
    });
  });
}
