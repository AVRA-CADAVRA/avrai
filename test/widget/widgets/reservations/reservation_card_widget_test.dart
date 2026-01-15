// Reservation Card Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for ReservationCardWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/reservation_card_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for ReservationCardWidget
/// Tests reservation card display and interactions
void main() {
  group('ReservationCardWidget Tests', () {
    // Removed: Property assignment tests
    // Reservation card tests focus on business logic (card display, tap handling), not property assignment

    testWidgets(
        'should display reservation information correctly, call onTap when tapped, or display ticket count when different from party size',
        (WidgetTester tester) async {
      // Test business logic: reservation card display and interactions
      final now = DateTime.now();
      final reservation1 = Reservation(
        id: 'res-1',
        agentId: 'agent-1',
        type: ReservationType.spot,
        targetId: 'spot-123',
        reservationTime: now.add(const Duration(days: 7)),
        partySize: 2,
        ticketCount: 2,
        status: ReservationStatus.confirmed,
        createdAt: now,
        updatedAt: now,
      );

      bool wasTapped = false;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: ReservationCardWidget(
          reservation: reservation1,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Spot'), findsOneWidget);
      expect(find.text('spot-123'), findsOneWidget);
      expect(find.text('2 people'), findsOneWidget);
      
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(wasTapped, isTrue);

      final reservation2 = Reservation(
        id: 'res-2',
        agentId: 'agent-2',
        type: ReservationType.event,
        targetId: 'event-456',
        reservationTime: now.add(const Duration(days: 3)),
        partySize: 4,
        ticketCount: 6,
        status: ReservationStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: ReservationCardWidget(
          reservation: reservation2,
          onTap: () {},
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('4 people'), findsOneWidget);
      expect(find.text('6 tickets'), findsOneWidget);
    });
  });
}
