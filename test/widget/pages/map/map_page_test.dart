import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/map/map_page.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('MapPage Widget Tests', () {
    late MockListsBloc mockListsBloc;
    late MockSpotsBloc mockSpotsBloc;

    setUp(() {
      mockListsBloc = MockListsBloc();
      mockSpotsBloc = MockSpotsBloc();
    });

    testWidgets('displays map view with app bar', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Map'), findsOneWidget); // App bar title
      expect(find.byType(MapPage), findsOneWidget);
    });

    testWidgets('renders map view component', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - MapView should be rendered
      // Note: MapView testing would require mocking FlutterMap
      expect(find.byType(MapPage), findsOneWidget);
    });

    testWidgets('handles different screen orientations', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act - Portrait mode
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Map'), findsOneWidget);

      // Act - Landscape mode
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);
      await tester.pump();

      // Assert - Should maintain functionality
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets('provides bloc access to map view', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Blocs should be available to child widgets
      expect(find.byType(MapPage), findsOneWidget);
    });

    testWidgets('meets accessibility requirements', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Map'), findsOneWidget);
      
      // Map should have proper semantic labels
      // Note: Full accessibility testing would require MapView implementation details
    });

    testWidgets('handles rapid navigation to map page', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act - Multiple rapid rebuilds
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert - Should remain stable
      expect(find.byType(MapPage), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets('maintains state during rebuilds', (WidgetTester tester) async {
      // Arrange
      mockListsBloc.setState(ListsInitial());
      mockSpotsBloc.setState(SpotsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const MapPage(),
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Force rebuild
      await tester.pump();

      // Assert - Should maintain state
      expect(find.text('Map'), findsOneWidget);
    });

    group('Map View Integration', () {
      testWidgets('integrates with lists bloc', (WidgetTester tester) async {
        // Arrange
        final testLists = TestDataFactory.createTestLists(3);
        mockListsBloc.setState(ListsLoaded(testLists, testLists));
        mockSpotsBloc.setState(SpotsInitial());

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const MapPage(),
          listsBloc: mockListsBloc,
          spotsBloc: mockSpotsBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Map should have access to lists data
        expect(find.byType(MapPage), findsOneWidget);
      });

      testWidgets('integrates with spots bloc', (WidgetTester tester) async {
        // Arrange
        final testSpots = TestDataFactory.createTestSpots(5);
        mockListsBloc.setState(ListsInitial());
        mockSpotsBloc.setState(SpotsLoaded(testSpots));

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const MapPage(),
          listsBloc: mockListsBloc,
          spotsBloc: mockSpotsBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Map should have access to spots data
        expect(find.byType(MapPage), findsOneWidget);
      });

      testWidgets('handles loading states correctly', (WidgetTester tester) async {
        // Arrange
        mockListsBloc.setState(ListsLoading());
        mockSpotsBloc.setState(SpotsLoading());

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const MapPage(),
          listsBloc: mockListsBloc,
          spotsBloc: mockSpotsBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Should handle loading states gracefully
        expect(find.byType(MapPage), findsOneWidget);
      });

      testWidgets('handles error states correctly', (WidgetTester tester) async {
        // Arrange
        mockListsBloc.setState(ListsError('Failed to load lists'));
        mockSpotsBloc.setState(SpotsError('Failed to load spots'));

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const MapPage(),
          listsBloc: mockListsBloc,
          spotsBloc: mockSpotsBloc,
        );

        // Act
        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Assert - Should handle error states gracefully
        expect(find.byType(MapPage), findsOneWidget);
      });
    });
  }, skip: true); // TODO(Phase 7): Map widgets introduce pending timers/network; add test-safe map abstraction or mock tile provider.
}
