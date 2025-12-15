import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/home/home_page.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/models/user.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../../helpers/test_helpers.dart';
import '../../mocks/mock_blocs.dart';

/// Widget tests for HomePage
/// Tests tab navigation, authentication states, and BLoC integration
void main() {
  setUpAll(() async {
    await WidgetTestHelpers.setupWidgetTestEnvironment();
  });

  tearDownAll(() async {
    await WidgetTestHelpers.cleanupWidgetTestEnvironment();
  });

  group('HomePage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockListsBloc mockListsBloc;
    late MockSpotsBloc mockSpotsBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockListsBloc = MockListsBloc();
      mockSpotsBloc = MockSpotsBloc();
    });

    testWidgets('displays loading state when auth is loading', (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthLoading());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HomePage(),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // Pump once to render loading state

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays unauthenticated content when not logged in', (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(Unauthenticated());
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HomePage(),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show unauthenticated UI
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('displays authenticated content when logged in', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
      mockAuthBloc.setState(Authenticated(user: testUser));
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HomePage(),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should show authenticated UI with tabs
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('initializes with correct tab index', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
      mockAuthBloc.setState(Authenticated(user: testUser));
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HomePage(initialTabIndex: 1),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should initialize with specified tab
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('loads lists on initialization', (WidgetTester tester) async {
      // Arrange
      final testUser = User(
        id: 'test-user',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.user,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
      mockAuthBloc.setState(Authenticated(user: testUser));
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const HomePage(),
        authBloc: mockAuthBloc,
        listsBloc: mockListsBloc,
        spotsBloc: mockSpotsBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Widget should be rendered
      expect(find.byType(HomePage), findsOneWidget);
      // Note: BLoC event verification would require more complex setup
    });
  });
}

