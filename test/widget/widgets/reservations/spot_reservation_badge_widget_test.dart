// Spot Reservation Badge Widget Tests
//
// Phase 15: Reservation System Implementation
// Section 15.2.3: Reservation Integration with Spots
//
// Widget tests for SpotReservationBadgeWidget

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/presentation/widgets/reservations/spot_reservation_badge_widget.dart';
import '../../helpers/widget_test_helpers.dart';

/// Widget tests for SpotReservationBadgeWidget
/// Tests spot reservation badge display and interactions
void main() {
  group('SpotReservationBadgeWidget Tests', () {
    testWidgets(
        'should display reservation badge correctly for all states, show appropriate badge text and icon, handle tap when available, or display limited capacity warning when capacity is low',
        (WidgetTester tester) async {
      // Test business logic: spot reservation badge display and interactions
      bool wasTapped = false;
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: SpotReservationBadgeWidget(
          isAvailable: true,
          hasExistingReservation: false,
          compact: true,
          onTap: () => wasTapped = true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.textContaining('Available'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(wasTapped, isTrue);

      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const SpotReservationBadgeWidget(
          isAvailable: false,
          hasExistingReservation: false,
          compact: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget2);
      expect(find.textContaining('Unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const SpotReservationBadgeWidget(
          isAvailable: true,
          hasExistingReservation: true,
          compact: false,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.textContaining('You have a reservation'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      final widget4 = WidgetTestHelpers.createTestableWidget(
        child: const SpotReservationBadgeWidget(
          isAvailable: true,
          hasExistingReservation: false,
          availableCapacity: 3,
          compact: true,
        ),
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget4);
      expect(find.textContaining('3 left'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
