import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots_core/spots_core.dart' as core;
import 'package:spots/core/models/user.dart';
import 'package:spots/injection_container.dart' as di;

import 'auth_remote_datasource_impl_test.mocks.dart';

@GenerateMocks([AuthBackend])
void main() {
  group('AuthRemoteDataSourceImpl', () {
    late AuthRemoteDataSourceImpl dataSource;
    late MockAuthBackend mockAuthBackend;

    setUp(() async {
      mockAuthBackend = MockAuthBackend();
      await di.sl.reset();
      di.sl.registerSingleton<AuthBackend>(mockAuthBackend);
      dataSource = AuthRemoteDataSourceImpl();
    });
    
    tearDown(() async {
      await di.sl.reset();
    });

    group('signIn', () {
      test('should sign in user via remote backend', () async {
        const email = 'test@example.com';
        const password = 'password123';
        final coreUser = core.User(
          id: 'user-123',
          email: email,
          name: 'Test User',
          displayName: 'Test User',
          role: core.UserRole.follower,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: true,
        );

        when(mockAuthBackend.signInWithEmailPassword(email, password))
            .thenAnswer((_) async => coreUser);
        
        final user = await dataSource.signIn(email, password);
        expect(user, isNotNull);
        expect(user?.email, equals(email));
        verify(mockAuthBackend.signInWithEmailPassword(email, password)).called(1);
      });
    });

    group('signUp', () {
      test('should sign up user via remote backend', () async {
        const email = 'new@example.com';
        const password = 'password123';
        const name = 'New User';

        final coreUser = core.User(
          id: 'user-123',
          email: email,
          name: name,
          displayName: name,
          role: core.UserRole.follower,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: true,
        );
        
        when(mockAuthBackend.registerWithEmailPassword(email, password, name))
            .thenAnswer((_) async => coreUser);
        
        final user = await dataSource.signUp(email, password, name);
        expect(user, isNotNull);
        expect(user?.email, equals(email));
        verify(mockAuthBackend.registerWithEmailPassword(email, password, name)).called(1);
      });
    });

    group('signOut', () {
      test('should sign out user', () async {
        when(mockAuthBackend.signOut()).thenAnswer((_) async {});
        await expectLater(
          dataSource.signOut(),
          completes,
        );
        verify(mockAuthBackend.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should get current user from remote', () async {
        when(mockAuthBackend.getCurrentUser()).thenAnswer((_) async => null);
        final user = await dataSource.getCurrentUser();

        // May return null if not authenticated
        expect(user, anyOf(isNull, isA<User>()));
        verify(mockAuthBackend.getCurrentUser()).called(1);
      });
    });

    group('updateUser', () {
      test('should update user via remote backend', () async {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Updated User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await dataSource.updateUser(user);

        expect(result, isNotNull);
        expect(result?.email, equals(user.email));
      });
    });
  });
}

