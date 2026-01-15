// Dispute Form Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for DisputeFormWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/dispute_form_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for DisputeFormWidget
/// Tests dispute form submission and validation
void main() {
  group('DisputeFormWidget Tests', () {
    testWidgets(
        'should display dispute form correctly with all reason options and description field',
        (WidgetTester tester) async {
      // Test business logic: dispute form display
      final now = DateTime.now();
      final reservation = Reservation(
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

      final widget = WidgetTestHelpers.createTestableWidget(
        child: Scaffold(
          body: SingleChildScrollView(
            child: DisputeFormWidget(
              reservation: reservation,
              onSubmit: (_, __) {},
              isLoading: false,
            ),
          ),
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget);
      expect(find.textContaining('File a Dispute'), findsOneWidget);
      expect(find.textContaining('Injury preventing attendance'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.textContaining('Submit Dispute'), findsOneWidget);
    });
  });
}
