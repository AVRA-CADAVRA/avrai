import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avrai/presentation/widgets/search/hybrid_search_results.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for HybridSearchResults
/// Tests search results display and BLoC integration
void main() {
  group('HybridSearchResults Widget Tests', () {
    // Removed: Property assignment tests
    // Hybrid search results tests focus on business logic (search results display, state management), not property assignment

    testWidgets(
        'should display initial state message, display loading state, or display error state',
        (WidgetTester tester) async {
      // Test business logic: hybrid search results display and state management
      final blocInitial = MockHybridSearchBloc()..setState(HybridSearchInitial());
      final widget1 = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: blocInitial,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget1);
      expect(find.text('Search for spots'), findsOneWidget);
      expect(find.text('Find community spots and external places'),
          findsOneWidget);

      final blocLoading = MockHybridSearchBloc()..setState(HybridSearchLoading());
      final widget2 = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: blocLoading,
      );
      await tester.pumpWidget(widget2);
      await tester.pump();
      expect(find.text('Searching community and external sources...'),
          findsOneWidget);

      final blocError =
          MockHybridSearchBloc()..setState(HybridSearchError('Test error'));
      final widget3 = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: blocError,
      );
      await WidgetTestHelpers.pumpAndSettle(tester, widget3);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets(
        'should display reservation badges and quick reservation buttons for community spots',
        (WidgetTester tester) async {
      // Test business logic: reservation badges and quick reservation buttons for reservable spots
      final communitySpot = Spot(
        id: 'spot1',
        name: 'Community Restaurant',
        description: 'A great community spot',
        latitude: 40.0,
        longitude: -74.0,
        category: 'restaurant',
        rating: 4.5,
        createdBy: 'user1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {}, // No is_external flag = community spot
      );

      final externalSpot = Spot(
        id: 'spot2',
        name: 'External Place',
        description: 'External place from Google',
        latitude: 40.1,
        longitude: -74.1,
        category: 'restaurant',
        rating: 4.0,
        createdBy: 'user2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: {'is_external': true}, // External spot
      );

      final blocLoaded = MockHybridSearchBloc()
        ..setState(
          HybridSearchLoaded(
            spots: [communitySpot, externalSpot],
            communityCount: 1,
            externalCount: 1,
            totalCount: 2,
            searchDuration: const Duration(milliseconds: 100),
            sources: {'community': 1, 'external': 1},
          ),
        );

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HybridSearchResults(),
        hybridSearchBloc: blocLoaded,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Community spot should show reservation badge and quick reservation button
      expect(find.text('Available'), findsOneWidget);
      expect(find.byIcon(Icons.event_available), findsWidgets); // Badge + button icon

      // Both spots should be displayed
      expect(find.text('Community Restaurant'), findsOneWidget);
      expect(find.text('External Place'), findsOneWidget);
    });
  });
}
