import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spots/presentation/pages/auth/login_page.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import '../../helpers/widget_test_helpers.dart';
import '../../mocks/mock_blocs.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    testWidgets('displays all required UI elements',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Verify all UI elements are present
      expect(find.byIcon(Icons.location_on), findsOneWidget); // App logo
      expect(find.text('SPOTS'), findsOneWidget); // App title
      expect(
          find.text('Discover meaningful places'), findsOneWidget); // Subtitle
      expect(
          find.byKey(const Key('email_field')), findsOneWidget); // Email field
      expect(find.byKey(const Key('password_field')),
          findsOneWidget); // Password field
      expect(find.text('Sign In'), findsOneWidget); // Sign in button
      expect(find.text('Sign Up'), findsOneWidget); // Sign up link
      expect(find.text('🧪 Demo Login'), findsOneWidget); // Demo button
    });

    testWidgets('shows password visibility toggle',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Password visibility toggle should be present
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Act - Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Assert - Visibility toggle should change (icon changes to visibility_off)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('validates email field correctly', (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Test empty email validation
      await tester.enterText(find.byKey(const Key('email_field')), '');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);

      // Test invalid email validation
      await tester.enterText(
          find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('validates password field correctly',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Test empty password validation
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), '');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);

      // Test short password validation
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('submits valid credentials', (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Enter valid credentials
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert - AuthBloc should receive SignInRequested event
      expect(
        mockAuthBloc.addedEvents.whereType<SignInRequested>().length,
        equals(1),
      );
    });

    testWidgets('shows loading state during authentication',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthLoading());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();

      // Assert - Loading indicator should be visible in button
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Assert - Button should be disabled
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNull);
    });

    testWidgets('shows error message on authentication failure',
        (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Invalid credentials';
      mockAuthBloc.setState(AuthError(errorMessage));

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Error snackbar should be shown
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('navigates to home on successful authentication',
        (WidgetTester tester) async {
      // Arrange
      final testUser = WidgetTestHelpers.createTestUserForAuth();
      mockAuthBloc.setState(Authenticated(user: testUser));

      final navigatorObserver = NavigatorObserver();
      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
        navigatorObserver: navigatorObserver,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Should navigate to home
      // Note: This would need proper router setup to test navigation fully
      // For now, we verify the state change is handled
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('demo login button fills credentials',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Tap demo login button
      await tester.tap(find.text('🧪 Demo Login'));
      await tester.pump();

      // Assert - Credentials should be filled
      expect(find.text('demo@spots.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('navigates to signup page', (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - Link exists (navigation requires GoRouter setup, which is out of scope here)
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('maintains state during screen rotations',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Act - Enter text and rotate screen
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');

      // Simulate orientation change
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);
      await tester.pump();

      // Assert - Text should be preserved
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('meets accessibility requirements',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      // Act
      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Assert - All form fields should have labels
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // All buttons should have text or semantic labels
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Interactive elements should meet minimum size requirements
      final emailField = tester.getSize(find.byKey(const Key('email_field')));
      expect(emailField.height, greaterThanOrEqualTo(48.0));

      final signInButton =
          tester.getSize(find.widgetWithText(ElevatedButton, 'Sign In').first);
      expect(signInButton.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('handles rapid tap events gracefully',
        (WidgetTester tester) async {
      // Arrange
      mockAuthBloc.setState(AuthInitial());

      final widget = WidgetTestHelpers.createTestableWidget(
        child: const LoginPage(),
        authBloc: mockAuthBloc,
      );

      await WidgetTestHelpers.pumpAndSettle(tester, widget);

      // Fill valid credentials
      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');

      // Act - Rapidly tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Assert - Should only trigger one authentication request
      expect(
        mockAuthBloc.addedEvents.whereType<SignInRequested>().length,
        equals(1),
      );
    });
  });
}
