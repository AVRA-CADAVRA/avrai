// Cancellation Policy Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget tests for CancellationPolicyWidget

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/cancellation_policy_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for CancellationPolicyWidget
/// Tests cancellation policy display and refund calculation
void main() {
  group('CancellationPolicyWidget Tests', () {
    testWidgets(
        'should display policy correctly, show refund eligibility when within policy window, show refund amount when eligible, or display no refund message when outside policy window',
        (WidgetTester tester) async {
      // Test business logic: cancellation policy display and refund calculation
      final now = DateTime.now();
      final policy = CancellationPolicy.defaultPolicy();
      final reservationTime = now.add(const Duration(days: 2)); // 48 hours away (within 24-hour window)

      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: CancellationPolicyWidget(
          policy: policy,
          reservationTime: reservationTime,
          ticketPrice: 50.0,
          ticketCount: 2,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.textContaining('Refund Eligible'), findsOneWidget);
      expect(find.textContaining('Cancel at least 24 hours'), findsOneWidget);
      expect(find.textContaining('\$100.00'), findsOneWidget);

      final pastTime = now.subtract(const Duration(hours: 1));
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: CancellationPolicyWidget(
          policy: policy,
          reservationTime: pastTime,
          ticketPrice: 50.0,
          ticketCount: 2,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.textContaining('Refund Not Eligible'), findsOneWidget);
      expect(find.textContaining('You can still cancel'), findsOneWidget);

      final partialPolicy = CancellationPolicy(
        hoursBefore: 24,
        fullRefund: false,
        partialRefund: true,
        refundPercentage: 0.5,
      );
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: CancellationPolicyWidget(
          policy: partialPolicy,
          reservationTime: reservationTime,
          ticketPrice: 50.0,
          ticketCount: 2,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('Refund Eligible'), findsOneWidget);
      expect(find.textContaining('50%'), findsOneWidget);
      expect(find.textContaining('\$50.00'), findsOneWidget);
    });
  });
}
