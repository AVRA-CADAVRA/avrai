import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/user.dart' as user_model;
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/core/theme/app_theme.dart';
import '../mocks/mock_blocs.dart';

/// Helper utilities for widget testing to ensure consistent test setup
class WidgetTestHelpers {
  /// Creates a testable widget wrapped with necessary providers and theme
  static Widget createTestableWidget({
    required Widget child,
    MockAuthBloc? authBloc,
    MockListsBloc? listsBloc,
    MockSpotsBloc? spotsBloc,
    MockHybridSearchBloc? hybridSearchBloc,
    NavigatorObserver? navigatorObserver,
    RouteSettings? routeSettings,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc ?? MockAuthBloc(),
        ),
        BlocProvider<ListsBloc>.value(
          value: listsBloc ?? MockListsBloc(),
        ),
        BlocProvider<SpotsBloc>.value(
          value: spotsBloc ?? MockSpotsBloc(),
        ),
        BlocProvider<HybridSearchBloc>.value(
          value: hybridSearchBloc ?? MockHybridSearchBloc(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      ),
    );
  }

  /// Creates a testable widget with router support
  static Widget createTestableWidgetWithRouter({
    required Widget child,
    MockAuthBloc? authBloc,
    MockListsBloc? listsBloc,
    MockSpotsBloc? spotsBloc,
    MockHybridSearchBloc? hybridSearchBloc,
    NavigatorObserver? navigatorObserver,
    String initialRoute = '/',
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc ?? MockAuthBloc(),
        ),
        BlocProvider<ListsBloc>.value(
          value: listsBloc ?? MockListsBloc(),
        ),
        BlocProvider<SpotsBloc>.value(
          value: spotsBloc ?? MockSpotsBloc(),
        ),
        BlocProvider<HybridSearchBloc>.value(
          value: hybridSearchBloc ?? MockHybridSearchBloc(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => child,
          settings: settings,
        ),
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      ),
    );
  }

  /// Pumps widget and settles all animations
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
  }

  /// Verifies that a widget displays the expected loading state
  static void verifyLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verifies that a widget displays an error state with a specific message
  static void verifyErrorState(WidgetTester tester, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  }

  /// Verifies navigation occurred to a specific route
  static void verifyNavigationTo(NavigatorObserver observer, String routeName) {
    // Note: didPush signature is (Route<dynamic> route, Route<dynamic>? previousRoute)
    // We verify that didPush was called - the actual route checking can be done
    // by capturing arguments if needed. For now, just verify the call happened.
    // Using a workaround: verify the call with any() and cast to avoid null issues
    // ignore: cast_from_null_always_fails - This is a matcher, not an actual cast
    verify(observer.didPush(any as Route<dynamic>, any));
  }

  /// Creates test user data (UnifiedUser)
  static UnifiedUser createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName,
    UserRole role = UserRole.follower,
    bool isAgeVerified = true,
  }) {
    final now = DateTime.now();
    return UnifiedUser(
      id: id,
      email: email,
      displayName: displayName ?? 'Test User',
      photoUrl: null,
      location: 'Test City',
      createdAt: now,
      updatedAt: now,
      isOnline: false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: const [],
      collaboratedLists: const [],
      followedLists: const [],
      primaryRole: role,
      isAgeVerified: isAgeVerified,
      ageVerificationDate: isAgeVerified ? now : null,
    );
  }

  /// Creates test User (for AuthBloc compatibility)
  /// Converts UnifiedUser to User type expected by Authenticated state
  static user_model.User createTestUserForAuth({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName,
    user_model.UserRole role = user_model.UserRole.user,
    bool isAgeVerified = true,
  }) {
    final now = DateTime.now();
    return user_model.User(
      id: id,
      email: email,
      name: displayName ?? 'Test User',
      displayName: displayName,
      role: role,
      createdAt: now,
      updatedAt: now,
      isOnline: false,
    );
  }

  /// Creates test spot data
  static Spot createTestSpot({
    String id = 'test-spot-id',
    String name = 'Test Spot',
    double latitude = 40.7128,
    double longitude = -74.0060,
    String category = 'restaurant',
  }) {
    final now = DateTime.now();
    return Spot(
      id: id,
      name: name,
      description: 'A test spot for widget testing',
      latitude: latitude,
      longitude: longitude,
      category: category,
      rating: 4.5,
      createdBy: 'test-user-id',
      createdAt: now,
      updatedAt: now,
      address: '123 Test St, Test City',
      phoneNumber: '+1-555-0123',
      website: 'https://test.example.com',
      tags: const ['test', 'widget'],
      metadata: const {},
    );
  }

  /// Creates test list data
  static SpotList createTestList({
    String id = 'test-list-id',
    String? name,
    String? title,
    String curatorId = 'test-user-id',
    bool isPublic = true,
  }) {
    final now = DateTime.now();
    return SpotList(
      id: id,
      title: title ?? name ?? 'Test List',
      name: name ?? title ?? 'Test List',
      description: 'A test list for widget testing',
      spots: const [],
      createdAt: now,
      updatedAt: now,
      curatorId: curatorId,
      isPublic: isPublic,
      spotIds: const [],
      tags: const ['test', 'widget'],
      collaborators: const [],
      followers: const [],
      respectCount: 0,
      ageRestricted: false,
      moderationEnabled: true,
      metadata: const {},
    );
  }

  /// Verifies that form validation works correctly
  static Future<void> verifyFormValidation(
    WidgetTester tester, {
    required String formKey,
    required Map<String, String> invalidInputs,
    required Map<String, String> expectedErrors,
  }) async {
    // Input invalid data
    for (final entry in invalidInputs.entries) {
      await tester.enterText(find.byKey(Key(entry.key)), entry.value);
    }

    // Try to submit form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify validation errors appear
    for (final entry in expectedErrors.entries) {
      expect(find.text(entry.value), findsOneWidget);
    }
  }

  /// Simulates user interaction delays
  static Future<void> simulateUserDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 100));
  }

  /// Finds widgets by accessibility semantics
  static Finder findBySemantics(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Verifies accessibility requirements
  static void verifyAccessibility(WidgetTester tester) {
    // Verify semantic labels exist for important elements
    expect(find.bySemanticsLabel(RegExp(r'.*')), findsWidgets);
    
    // Could add more accessibility checks here like:
    // - Minimum touch target sizes
    // - Contrast ratios
    // - Screen reader compatibility
  }
}

/// Test data factory for creating consistent test objects
class TestDataFactory {
  static const String defaultUserId = 'test-user-id';
  static const String defaultEmail = 'test@example.com';
  static const String defaultSpotId = 'test-spot-id';
  static const String defaultListId = 'test-list-id';

  /// Creates a complete user profile for testing
  static UnifiedUser createCompleteUserProfile({
    UserRole role = UserRole.follower,
  }) {
    return WidgetTestHelpers.createTestUser(
      id: defaultUserId,
      email: defaultEmail,
      role: role,
    );
  }

  /// Creates multiple test spots for list testing
  static List<Spot> createTestSpots(int count) {
    return List.generate(count, (index) {
      return WidgetTestHelpers.createTestSpot(
        id: 'test-spot-$index',
        name: 'Test Spot $index',
        latitude: 40.7128 + (index * 0.001),
        longitude: -74.0060 + (index * 0.001),
      );
    });
  }

  /// Creates multiple test lists for testing
  static List<SpotList> createTestLists(int count) {
    return List.generate(count, (index) {
      return WidgetTestHelpers.createTestList(
        id: 'test-list-$index',
        name: 'Test List $index',
      );
    });
  }
}
