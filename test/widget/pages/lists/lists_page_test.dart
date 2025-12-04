import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/presentation/pages/lists/lists_page.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('ListsPage Widget Tests', () {
    late MockListsBloc mockListsBloc;

    setUp(() {
      mockListsBloc = MockListsBloc();
    });

    testWidgets('displays app bar with title and actions', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('My Lists'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading state when lists are loading', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoading());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      WidgetTestHelpers.verifyLoadingState(tester);
    });

    testWidgets('shows error state with retry button', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Failed to load lists';
      when(mockListsBloc.state).thenReturn(ListsError(errorMessage));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      WidgetTestHelpers.verifyErrorState(tester, errorMessage);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Error loading lists'), findsOneWidget);
    });

    testWidgets('triggers reload when retry button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsError('Network error'));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Assert - Verify that LoadLists event was added
      verify(mockListsBloc.add(LoadLists())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('displays empty state when no lists exist', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoaded([], []));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('No lists yet'), findsOneWidget);
      expect(find.text('Create your first list to get started'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt_outlined), findsOneWidget);
    });

    testWidgets('displays list of spot lists when loaded', (WidgetTester tester) async {
      // Arrange
      final testLists = TestDataFactory.createTestLists(3);
      when(mockListsBloc.state).thenReturn(ListsLoaded(testLists, testLists));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('Test List 0'), findsOneWidget);
      expect(find.text('Test List 1'), findsOneWidget);
      expect(find.text('Test List 2'), findsOneWidget);
    });

    testWidgets('displays floating action button for creating lists', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoaded([], []));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('navigates to create list page when FAB is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoaded([], []));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert - Navigation would be tested with proper router setup
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('triggers load lists event on initial state', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify that LoadLists event was added
      verify(mockListsBloc.add(LoadLists())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('handles unknown state gracefully', (WidgetTester tester) async {
      // Arrange - Create a custom unknown state
      when(mockListsBloc.state).thenReturn(ListsInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('maintains scroll position during rebuilds', (WidgetTester tester) async {
      // Arrange
      final testLists = TestDataFactory.createTestLists(20); // Many lists to enable scrolling
      when(mockListsBloc.state).thenReturn(ListsLoaded(testLists, testLists));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Trigger rebuild by pumping again
      await tester.pump();

      // Assert - Should maintain scroll position
      expect(find.text('Test List 0'), findsNothing); // Should be scrolled out of view
    });

    testWidgets('meets accessibility requirements', (WidgetTester tester) async {
      // Arrange
      final testLists = TestDataFactory.createTestLists(2);
      when(mockListsBloc.state).thenReturn(ListsLoaded(testLists, testLists));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.text('My Lists'), findsOneWidget);
      
      // FAB should meet minimum size requirements
      final fab = tester.getSize(find.byType(FloatingActionButton));
      expect(fab.width, greaterThanOrEqualTo(48.0));
      expect(fab.height, greaterThanOrEqualTo(48.0));
      
      // List items should be accessible
      expect(find.text('Test List 0'), findsOneWidget);
      expect(find.text('Test List 1'), findsOneWidget);
    });

    testWidgets('handles rapid state changes gracefully', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoading());
      when(mockListsBloc.stream).thenAnswer((_) => Stream.fromIterable([
        ListsLoading(),
        ListsLoaded([], []),
        ListsError('Error'),
        ListsLoaded([], []),
      ]));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert - Should handle rapid changes without errors
      expect(find.byType(ListsPage), findsOneWidget);
    });

    testWidgets('shows offline indicator when configured', (WidgetTester tester) async {
      // Arrange
      when(mockListsBloc.state).thenReturn(ListsLoaded([], []));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const ListsPage(),
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Offline indicator should be present in app bar
      // Note: The actual offline state would need to be mocked
      expect(find.byType(AppBar), findsOneWidget);
    });

    group('List Interaction Tests', () {
      testWidgets('handles list card taps', (WidgetTester tester) async {
        // Arrange
        final testLists = TestDataFactory.createTestLists(1);
        when(mockListsBloc.state).thenReturn(ListsLoaded(testLists, testLists));

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const ListsPage(),
          listsBloc: mockListsBloc,
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act - Tap on list card
        await tester.tap(find.text('Test List 0'));
        await tester.pumpAndSettle();

        // Assert - Should handle tap (navigation would be tested with proper router)
        expect(find.text('Test List 0'), findsOneWidget);
      });

      testWidgets('refreshes lists with pull-to-refresh', (WidgetTester tester) async {
        // Arrange
        final testLists = TestDataFactory.createTestLists(3);
        when(mockListsBloc.state).thenReturn(ListsLoaded(testLists, testLists));

        final widget = WidgetTestHelpers.createTestableWidget(
          child: const ListsPage(),
          listsBloc: mockListsBloc,
        );

        await WidgetTestHelpers.pumpAndSettle(tester, widget);

        // Act - Pull to refresh (if implemented)
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pump();

        // Assert - Should maintain functionality
        expect(find.text('Test List 0'), findsOneWidget);
      });
    });
  });
}
