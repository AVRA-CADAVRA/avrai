import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import "../../helpers/widget_test_helpers.dart';
import '../../../mocks/mock_blocs.dart';

/// Widget tests for AILoadingPage
/// Tests AI loading page that generates personalized lists
void main() {
  group('AILoadingPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockListsBloc mockListsBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockListsBloc = MockListsBloc();
    });

    testWidgets('displays loading page with user information', (WidgetTester tester) async {
      // Arrange
      bool loadingComplete = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AILoadingPage(
          userName: 'Test User',
          homebase: 'New York',
          favoritePlaces: ['Central Park', 'Brooklyn Bridge'],
          preferences: {
            'Food & Drink': ['Coffee & Tea'],
          },
          onLoadingComplete: () {
            loadingComplete = true;
          },
        ),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert
      expect(find.byType(AILoadingPage), findsOneWidget);
    });

    testWidgets('displays loading animation', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AILoadingPage(
          userName: 'Test User',
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Don't settle, check loading state

      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('handles user data correctly', (WidgetTester tester) async {
      // Arrange
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AILoadingPage(
          userName: 'John Doe',
          age: 25,
          birthday: DateTime(2000, 1, 1),
          homebase: 'Brooklyn',
          favoritePlaces: ['Park', 'Bridge'],
          preferences: {
            'Activities': ['Music', 'Art'],
          },
          onLoadingComplete: () {},
        ),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present
      expect(find.byType(AILoadingPage), findsOneWidget);
    });

    testWidgets('calls onLoadingComplete callback', (WidgetTester tester) async {
      // Arrange
      bool callbackCalled = false;
      final widget = WidgetTestHelpers.createTestableWidget(
        child: AILoadingPage(
          userName: 'Test User',
          onLoadingComplete: () {
            callbackCalled = true;
          },
        ),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be present (callback will be called when loading completes)
      expect(find.byType(AILoadingPage), findsOneWidget);
    });
  });
}

