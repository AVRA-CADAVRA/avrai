// Reservation Stats Widget Test
//
// Phase 15: Reservation System Implementation
// Section 15.3.1: Business Reservation Dashboard
//
// Widget tests for ReservationStatsWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/presentation/widgets/business/reservations/reservation_stats_widget.dart';

void main() {
  group('ReservationStatsWidget', () {
    testWidgets('should display statistics for reservations',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final reservations = <Reservation>[
        Reservation(
          id: '1',
          agentId: 'agent1',
          type: ReservationType.business,
          targetId: 'business1',
          reservationTime: now,
          partySize: 2,
          ticketCount: 2,
          status: ReservationStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
        Reservation(
          id: '2',
          agentId: 'agent2',
          type: ReservationType.business,
          targetId: 'business1',
          reservationTime: now,
          partySize: 4,
          ticketCount: 4,
          status: ReservationStatus.confirmed,
          createdAt: now,
          updatedAt: now,
        ),
        Reservation(
          id: '3',
          agentId: 'agent3',
          type: ReservationType.business,
          targetId: 'business1',
          reservationTime: now,
          partySize: 1,
          ticketCount: 1,
          status: ReservationStatus.confirmed,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationStatsWidget(
              reservations: reservations,
            ),
          ),
        ),
      );

      // Check that statistics are displayed
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('3'), findsNWidgets(2)); // Total and one other stat
      expect(find.text('1'), findsNWidgets(2)); // Pending and today
      expect(find.text('2'), findsOneWidget); // Confirmed
    });

    testWidgets('should display empty state when no reservations',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationStatsWidget(
              reservations: [],
            ),
          ),
        ),
      );

      // Check that statistics are displayed even with empty list
      expect(find.text('Statistics'), findsOneWidget);
      expect(
          find.text('0'), findsNWidgets(4)); // Total, Pending, Confirmed, Today
    });

    testWidgets('should calculate today count correctly',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final reservations = <Reservation>[
        Reservation(
          id: '1',
          agentId: 'agent1',
          type: ReservationType.business,
          targetId: 'business1',
          reservationTime: today.add(const Duration(hours: 10)),
          partySize: 2,
          ticketCount: 2,
          status: ReservationStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
        Reservation(
          id: '2',
          agentId: 'agent2',
          type: ReservationType.business,
          targetId: 'business1',
          reservationTime: tomorrow,
          partySize: 4,
          ticketCount: 4,
          status: ReservationStatus.confirmed,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationStatsWidget(
              reservations: reservations,
            ),
          ),
        ),
      );

      // Today's count should be 1 (only the first reservation is today)
      // Total = 2, Pending = 1, Confirmed = 1, Today = 1
      expect(find.text('2'), findsOneWidget); // Total
      expect(find.text('1'), findsNWidgets(3)); // Pending, Confirmed, Today
    });
  });
}
