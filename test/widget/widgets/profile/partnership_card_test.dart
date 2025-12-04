import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/profile/partnership_card.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('ProfilePartnershipCard', () {
    testWidgets('displays partnership information', (WidgetTester tester) async {
      // Arrange
      final partnership = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.business,
        partnerId: 'b1',
        partnerName: 'Test Business',
        status: PartnershipStatus.active,
        eventCount: 5,
        startDate: DateTime(2024, 1, 1),
      );

      const widget = ProfilePartnershipCard(
        partnership: partnership,
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Business'), findsOneWidget);
      expect(find.text('5 events'), findsOneWidget);
    });

    testWidgets('displays status badge', (WidgetTester tester) async {
      // Arrange
      final partnership = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.business,
        partnerId: 'b1',
        partnerName: 'Test Business',
        status: PartnershipStatus.active,
      );

      const widget = ProfilePartnershipCard(
        partnership: partnership,
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays type badge', (WidgetTester tester) async {
      // Arrange
      final partnership = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.brand,
        partnerId: 'br1',
        partnerName: 'Test Brand',
        status: PartnershipStatus.active,
      );

      const widget = ProfilePartnershipCard(
        partnership: partnership,
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Brand Partnership'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      // Arrange
      var tapped = false;
      final partnership = UserPartnership(
        id: '1',
        type: ProfilePartnershipType.business,
        partnerId: 'b1',
        partnerName: 'Test Business',
        status: PartnershipStatus.active,
      );

      final widget = ProfilePartnershipCard(
        partnership: partnership,
        onTap: () {
          tapped = true;
        },
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProfilePartnershipCard));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, isTrue);
    });
  });
}

