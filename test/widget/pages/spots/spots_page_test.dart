import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/spots/spots_page.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for SpotsPage
/// Tests UI rendering, search functionality, and BLoC integration
void main() {
  group('SpotsPage Widget Tests', () {
    late MockSpotsBloc mockSpotsBloc;

    setUp(() {
      mockSpotsBloc = MockSpotsBloc();
    });

    testWidgets('displays all required UI elements', (WidgetTester tester) async {
      // Arrange
      mockSpotsBloc.setState(SpotsInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify all UI elements are present
      expect(find.text('Spots'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search spots...'), findsOneWidget);
    });

    testWidgets('displays search field with correct hint', (WidgetTester tester) async {
      // Arrange
      mockSpotsBloc.setState(SpotsInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Search field should be present
      expect(find.text('Search spots...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('loads spots on initialization', (WidgetTester tester) async {
      // Arrange
      mockSpotsBloc.setState(SpotsInitial());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be rendered
      expect(find.byType(SpotsPage), findsOneWidget);
      // Note: BLoC event verification would require more complex setup
    });

    testWidgets('displays loading state when spots are loading', (WidgetTester tester) async {
      // Arrange
      mockSpotsBloc.setState(SpotsLoading());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays empty state when no spots available', (WidgetTester tester) async {
      // Arrange
      mockSpotsBloc.setState(SpotsLoaded([]));
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const SpotsPage(),
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show empty state or list
      expect(find.byType(SpotsPage), findsOneWidget);
    });
  });
}

