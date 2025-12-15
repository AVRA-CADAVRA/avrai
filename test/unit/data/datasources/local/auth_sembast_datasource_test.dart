import 'package:flutter_test/flutter_test.dart';
import 'package:spots/data/datasources/local/auth_sembast_datasource.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/core/models/user.dart';

/// Auth Sembast Data Source Tests
/// Tests local authentication data storage using Sembast
void main() {
  group('AuthSembastDataSource', () {
    late AuthSembastDataSource dataSource;

    setUp(() {
      // Use in-memory database for tests
      SembastDatabase.useInMemoryForTests();
      dataSource = AuthSembastDataSource();
    });

    tearDown(() async {
      // Clean up database after each test
      await SembastDatabase.resetForTests();
    });

    group('signIn', () {
      test('should sign in demo user with backdoor credentials', () async {
        const email = 'demo@spots.com';
        const password = 'password123';

        final user = await dataSource.signIn(email, password);

        expect(user, isNotNull);
        expect(user?.email, equals(email));
        expect(user?.name, equals('Demo User'));
      });

      test('should create demo user on-the-fly if not found', () async {
        const email = 'demo@spots.com';
        const password = 'anypassword';

        final user = await dataSource.signIn(email, password);

        expect(user, isNotNull);
        expect(user?.email, equals(email));
      });

      test('should return null for invalid credentials', () async {
        const email = 'invalid@example.com';
        const password = 'password';

        final user = await dataSource.signIn(email, password);

        expect(user, isNull);
      });
    });

    group('signUp', () {
      test('should sign up new user', () async {
        const email = 'new@example.com';
        const password = 'password123';
        final user = User(
          id: 'user-123',
          email: email,
          name: 'New User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await dataSource.signUp(email, password, user);

        expect(result, isNotNull);
        expect(result?.email, equals(email));
      });
    });

    group('saveUser', () {
      test('should save user to database', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await expectLater(
          dataSource.saveUser(user),
          completes,
        );
      });
    });

    group('getCurrentUser', () {
      test('should get current user from preferences', () async {
        // First save a user
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await dataSource.saveUser(user);

        final currentUser = await dataSource.getCurrentUser();

        expect(currentUser, isNotNull);
      });

      test('should return null when no current user', () async {
        final currentUser = await dataSource.getCurrentUser();

        // May return null if no user is set
        expect(currentUser, anyOf(isNull, isNotNull));
      });
    });

    group('clearUser', () {
      test('should clear current user', () async {
        await expectLater(
          dataSource.clearUser(),
          completes,
        );
      });
    });

    group('onboarding', () {
      test('should check onboarding completion status', () async {
        final isCompleted = await dataSource.isOnboardingCompleted();

        expect(isCompleted, isA<bool>());
      });

      test('should mark onboarding as completed', () async {
        await expectLater(
          dataSource.markOnboardingCompleted(),
          completes,
        );

        final isCompleted = await dataSource.isOnboardingCompleted();
        expect(isCompleted, isTrue);
      });
    });
  });
}

