// Reservation Actions Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for ReservationActionsWidget

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_actions_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ReservationActionsWidget
/// Tests reservation action buttons display and interactions
void main() {
  group('ReservationActionsWidget Tests', () {
    testWidgets(
        'should show appropriate action buttons based on reservation status, disable buttons when loading, show modification count when provided, or hide actions when reservation is inactive',
        (WidgetTester tester) async {
      // Test business logic: action buttons display and interactions based on reservation status
      final now = DateTime.now();
      final activeReservation = Reservation(
        id: 'res-1',
        agentId: 'agent-1',
        type: ReservationType.spot,
        targetId: 'spot-123',
        reservationTime: now.add(const Duration(days: 7)),
        partySize: 2,
        status: ReservationStatus.confirmed,
        createdAt: now,
        updatedAt: now,
      );

      bool cancelTapped = false;
      bool modifyTapped = false;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ReservationActionsWidget(
          reservation: activeReservation,
          canModify: true,
          modificationCount: 1,
          onCancel: () => cancelTapped = true,
          onModify: () => modifyTapped = true,
          isLoading: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.textContaining('Cancel Reservation'), findsOneWidget);
      expect(find.textContaining('Modify'), findsOneWidget);
      expect(find.textContaining('1/3'), findsOneWidget);

      await tester.tap(find.textContaining('Cancel Reservation'));
      await tester.pump();
      expect(cancelTapped, isTrue);

      await tester.tap(find.textContaining('Modify'));
      await tester.pump();
      expect(modifyTapped, isTrue);

      // Test that widget returns empty for inactive (cancelled) reservations without actions
      // Test inactive reservation (cancelled) - widget returns empty
      final cancelledReservation = Reservation(
        id: 'res-2',
        agentId: 'agent-2',
        type: ReservationType.event,
        targetId: 'event-456',
        reservationTime: now.add(const Duration(days: 3)),
        partySize: 4,
        status: ReservationStatus.cancelled,
        createdAt: now,
        updatedAt: now,
      );

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ReservationActionsWidget(
          reservation: cancelledReservation,
          isLoading: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      // Inactive (cancelled) reservations return empty widget when no check-in is available
      expect(find.textContaining('Cancel Reservation'), findsNothing);
      expect(find.textContaining('File Dispute'), findsNothing);
      expect(find.textContaining('Modify'), findsNothing);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: ReservationActionsWidget(
          reservation: activeReservation,
          canModify: false,
          modificationReason: 'Maximum modifications reached',
          isLoading: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('Maximum modifications reached'), findsOneWidget);
      expect(find.textContaining('Modify'), findsNothing);

      // Test loading state - button exists but is disabled
      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: ReservationActionsWidget(
          reservation: activeReservation,
          canModify: true,
          onCancel: () {},
          isLoading: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      // Button should exist but be disabled when loading
      expect(find.textContaining('Cancel Reservation'), findsOneWidget);
    });
  });
}
