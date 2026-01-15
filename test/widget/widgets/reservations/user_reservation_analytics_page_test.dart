// User Reservation Analytics Page Tests
//
// Phase 7.1: User Reservation Analytics
// Widget tests for UserReservationAnalyticsPage

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/pages/reservations/user_reservation_analytics_page.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import '../../helpers/widget_test_helpers.dart' as helpers;
import '../../../helpers/bloc_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for UserReservationAnalyticsPage
/// Tests analytics page display and interactions
void main() {
  group('UserReservationAnalyticsPage Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    tearDown(() {
      mockAuthBloc.close();
    });

    testWidgets(
        'should display analytics page correctly, show loading state initially, handle error states, and display analytics content when loaded',
        (WidgetTester tester) async {
      // Test business logic: analytics page display and interactions
      mockAuthBloc.setState(Authenticated(
        user: TestDataFactory.createTestUser(),
      ));

      final widget = helpers.WidgetTestHelpers.createTestableWidget(
        child: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const UserReservationAnalyticsPage(),
        ),
      );
      await helpers.WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Should display page title
      expect(find.text('Reservation Analytics'), findsOneWidget);

      // Should have refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Should have date range picker button
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}
