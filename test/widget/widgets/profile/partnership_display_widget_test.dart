import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/widgets/profile/partnership_display_widget.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/models/event_partnership.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('PartnershipDisplayWidget', () {
    testWidgets('displays empty state when no partnerships', (WidgetTester tester) async {
      // Arrange
      const widget = PartnershipDisplayWidget(
        partnerships: [],
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No partnerships yet'), findsOneWidget);
    });

    testWidgets('displays partnerships list', (WidgetTester tester) async {
      // Arrange
      final partnerships = [
        UserPartnership(
          id: '1',
          type: ProfilePartnershipType.business,
          partnerId: 'b1',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
          eventCount: 5,
        ),
      ];

      final widget = PartnershipDisplayWidget(
        partnerships: partnerships,
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Partnerships'), findsOneWidget);
      expect(find.text('Test Business'), findsOneWidget);
    });

    testWidgets('shows view all link when partnerships exceed max count', (WidgetTester tester) async {
      // Arrange
      final partnerships = List.generate(5, (i) => UserPartnership(
        id: '$i',
        type: ProfilePartnershipType.business,
        partnerId: 'b$i',
        partnerName: 'Business $i',
        status: PartnershipStatus.active,
      ));

      final widget = PartnershipDisplayWidget(
        partnerships: partnerships,
        maxDisplayCount: 3,
        onViewAllTap: (_) {},
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('View All'), findsOneWidget);
    });

    testWidgets('filters partnerships by type', (WidgetTester tester) async {
      // Arrange
      final partnerships = [
        UserPartnership(
          id: '1',
          type: ProfilePartnershipType.business,
          partnerId: 'b1',
          partnerName: 'Business',
          status: PartnershipStatus.active,
        ),
        UserPartnership(
          id: '2',
          type: ProfilePartnershipType.brand,
          partnerId: 'br1',
          partnerName: 'Brand',
          status: PartnershipStatus.active,
        ),
      ];

      final widget = PartnershipDisplayWidget(
        partnerships: partnerships,
        showFilters: true,
      );

      // Act
      final testableWidget = WidgetTestHelpers.createTestableWidget(
        child: widget,
        authBloc: MockAuthBloc(),
      );
      await tester.pumpWidget(testableWidget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });
  });
}

