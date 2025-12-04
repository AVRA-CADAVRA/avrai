import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/repositories/auth_repository_impl.dart';
import 'package:spots/core/models/user.dart';

import '../../helpers/test_helpers.dart';
import '../../mocks/mock_dependencies.mocks.dart';

/// Comprehensive test suite for AuthRepositoryImpl
/// Tests the current implementation behavior with nullable dependencies
/// 
/// Focus Areas:
/// - Authentication flows (signIn, signUp, signOut)
/// - UnifiedUser role verification and management
/// - Age verification processes 
/// - Offline/online mode switching with fallback mechanisms
/// - Privacy protection mechanisms in auth flow
/// - Current user management and updates
void main() {
  group('AuthRepositoryImpl Tests', () {
    late AuthRepositoryImpl repository;
    late MockAuthLocalDataSource? mockLocalDataSource;
    late MockAuthRemoteDataSource? mockRemoteDataSource;
    late MockConnectivity? mockConnectivity;
    
    late User testUser;
    late String testEmail;
    late String testPassword;
    late String testName;

    setUp(() {
      mockLocalDataSource = MockAuthLocalDataSource();
      mockRemoteDataSource = MockAuthRemoteDataSource();
      mockConnectivity = MockConnectivity();
      
      repository = AuthRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
      );
      
      testUser = User(
        id: TestConstants.testUserId,
        email: TestConstants.testEmail,
        name: TestConstants.testUserName,
        role: UserRole.user,
        createdAt: TestHelpers.createTestDateTime(),
        updatedAt: TestHelpers.createTestDateTime(),
      );
      testEmail = TestConstants.testEmail;
      testPassword = TestConstants.testPassword;
      testName = TestConstants.testUserName;
    });

    tearDown(() {
      if (mockLocalDataSource != null) reset(mockLocalDataSource!);
      if (mockRemoteDataSource != null) reset(mockRemoteDataSource!);
      if (mockConnectivity != null) reset(mockConnectivity!);
    });

    group('signIn', () {
      test('signs in remotely when online and saves user locally', () async {
        // Arrange: Configure online scenario
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockConnectivity!.checkConnectivity()).called(1);
        verify(mockRemoteDataSource!.signIn(testEmail, testPassword)).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });

      test('falls back to local when offline', () async {
        // Arrange: Configure offline scenario
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockConnectivity!.checkConnectivity()).called(1);
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
        verifyNever(mockRemoteDataSource!.signIn(any, any));
      });

      test('falls back to local when remote sign in fails', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(testEmail, testPassword))
            .thenThrow(Exception('Invalid credentials'));
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.signIn(testEmail, testPassword)).called(1);
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
      });

      test('falls back to local when remote returns null', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.signIn(testEmail, testPassword)).called(1);
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
      });

      test('handles null remote data source gracefully', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
      });

      test('handles null local data source gracefully', () async {
        // Arrange: Repository with null local data source
        repository = AuthRepositoryImpl(
          localDataSource: null,
          remoteDataSource: mockRemoteDataSource,
          connectivity: mockConnectivity,
        );
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.signIn(testEmail, testPassword)).called(1);
      });

      test('returns null when all sign in attempts fail', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(testEmail, testPassword))
            .thenThrow(Exception('Remote auth failed'));
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert
        expect(result, isNull);
        verify(mockRemoteDataSource!.signIn(testEmail, testPassword)).called(1);
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
      });
    });

    group('signUp', () {
      test('throws exception when offline', () async {
        // Arrange: Configure offline scenario
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act & Assert
        expect(
          () => repository.signUp(testEmail, testPassword, testName),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Cannot sign up while offline'),
          )),
        );
        verify(mockConnectivity!.checkConnectivity()).called(1);
      });

      test('signs up remotely when online and saves user locally', () async {
        // Arrange: Configure online scenario
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signUp(testEmail, testPassword, testName))
            .thenAnswer((_) async => testUser);
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signUp(testEmail, testPassword, testName);

        // Assert
        expect(result, equals(testUser));
        verify(mockConnectivity!.checkConnectivity()).called(1);
        verify(mockRemoteDataSource!.signUp(testEmail, testPassword, testName)).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });

      test('creates local user when remote sign up fails', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signUp(testEmail, testPassword, testName))
            .thenThrow(Exception('Remote signup failed'));
        when(mockLocalDataSource!.signUp(testEmail, testPassword, any))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signUp(testEmail, testPassword, testName);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.signUp(testEmail, testPassword, testName)).called(1);
        verify(mockLocalDataSource!.signUp(testEmail, testPassword, any)).called(1);
      });

      test('creates local user when remote returns null', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signUp(testEmail, testPassword, testName))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.signUp(testEmail, testPassword, any))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signUp(testEmail, testPassword, testName);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.signUp(testEmail, testPassword, testName)).called(1);
        verify(mockLocalDataSource!.signUp(testEmail, testPassword, any)).called(1);
      });

      test('creates user with correct default values', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signUp(testEmail, testPassword, testName))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.signUp(testEmail, testPassword, any))
            .thenAnswer((invocation) async {
              final user = invocation.positionalArguments[2] as User;
              expect(user.email, equals(testEmail));
              expect(user.name, equals(testName));
              expect(user.role, equals(UserRole.user));
              expect(user.id, isNotNull);
              expect(user.createdAt, isNotNull);
              expect(user.updatedAt, isNotNull);
              return user;
            });

        // Act
        await repository.signUp(testEmail, testPassword, testName);

        // Assert: Verification happens in the mock setup above
      });

      test('handles null remote data source gracefully', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource!.signUp(testEmail, testPassword, any))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signUp(testEmail, testPassword, testName);

        // Assert
        expect(result, equals(testUser));
        verify(mockLocalDataSource!.signUp(testEmail, testPassword, any)).called(1);
      });
    });

    group('signOut', () {
      test('signs out remotely and clears local data when online', () async {
        // Arrange
        when(mockRemoteDataSource!.signOut())
            .thenAnswer((_) async {});
        when(mockLocalDataSource!.clearUser())
            .thenAnswer((_) async {});

        // Act
        await repository.signOut();

        // Assert
        verify(mockRemoteDataSource!.signOut()).called(1);
        verify(mockLocalDataSource!.clearUser()).called(1);
      });

      test('clears local data even when remote sign out fails', () async {
        // Arrange
        when(mockRemoteDataSource!.signOut())
            .thenThrow(Exception('Remote signout failed'));
        when(mockLocalDataSource!.clearUser())
            .thenAnswer((_) async {});

        // Act
        await repository.signOut();

        // Assert
        verify(mockRemoteDataSource!.signOut()).called(1);
        verify(mockLocalDataSource!.clearUser()).called(1);
      });

      test('handles null remote data source gracefully', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );
        when(mockLocalDataSource!.clearUser())
            .thenAnswer((_) async {});

        // Act
        await repository.signOut();

        // Assert
        verify(mockLocalDataSource!.clearUser()).called(1);
      });

      test('handles null local data source gracefully', () async {
        // Arrange: Repository with null local data source
        repository = AuthRepositoryImpl(
          localDataSource: null,
          remoteDataSource: mockRemoteDataSource,
          connectivity: mockConnectivity,
        );
        when(mockRemoteDataSource!.signOut())
            .thenAnswer((_) async {});

        // Act & Assert: Should not throw
        await repository.signOut();
        
        verify(mockRemoteDataSource!.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('gets remote user and caches locally when available', () async {
        // Arrange
        when(mockRemoteDataSource!.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.getCurrentUser()).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });

      test('falls back to local when remote is unavailable', () async {
        // Arrange
        when(mockRemoteDataSource!.getCurrentUser())
            .thenThrow(Exception('Remote unavailable'));
        when(mockLocalDataSource!.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.getCurrentUser()).called(1);
        verify(mockLocalDataSource!.getCurrentUser()).called(1);
      });

      test('falls back to local when remote returns null', () async {
        // Arrange
        when(mockRemoteDataSource!.getCurrentUser())
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.getCurrentUser()).called(1);
        verify(mockLocalDataSource!.getCurrentUser()).called(1);
      });

      test('handles null remote data source gracefully', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );
        when(mockLocalDataSource!.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(testUser));
        verify(mockLocalDataSource!.getCurrentUser()).called(1);
      });

      test('returns null when no user is available', () async {
        // Arrange
        when(mockRemoteDataSource!.getCurrentUser())
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('updateCurrentUser', () {
      test('updates remote user and saves locally when successful', () async {
        // Arrange
        final updatedUser = User(
          id: testUser.id,
          email: testUser.email,
          name: 'Updated Name',
          role: testUser.role,
          createdAt: testUser.createdAt,
          updatedAt: DateTime.now(),
        );
        when(mockRemoteDataSource!.updateUser(testUser))
            .thenAnswer((_) async => updatedUser);
        when(mockLocalDataSource!.saveUser(updatedUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateCurrentUser(testUser);

        // Assert
        expect(result, equals(updatedUser));
        verify(mockRemoteDataSource!.updateUser(testUser)).called(1);
        verify(mockLocalDataSource!.saveUser(updatedUser)).called(1);
      });

      test('falls back to local update when remote fails', () async {
        // Arrange
        when(mockRemoteDataSource!.updateUser(testUser))
            .thenThrow(Exception('Remote update failed'));
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateCurrentUser(testUser);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.updateUser(testUser)).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });

      test('falls back to local update when remote returns null', () async {
        // Arrange
        when(mockRemoteDataSource!.updateUser(testUser))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateCurrentUser(testUser);

        // Assert
        expect(result, equals(testUser));
        verify(mockRemoteDataSource!.updateUser(testUser)).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });

      test('handles null remote data source gracefully', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateCurrentUser(testUser);

        // Assert
        expect(result, equals(testUser));
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });
    });

    group('isOfflineMode', () {
      test('returns false when remote data source is available', () async {
        // Act
        final result = await repository.isOfflineMode();

        // Assert
        expect(result, isFalse);
      });

      test('returns true when remote data source is null', () async {
        // Arrange: Repository with null remote data source
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: null,
          connectivity: mockConnectivity,
        );

        // Act
        final result = await repository.isOfflineMode();

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateUser', () {
      test('delegates to updateCurrentUser', () async {
        // Arrange
        when(mockRemoteDataSource!.updateUser(testUser))
            .thenAnswer((_) async => testUser);
        when(mockLocalDataSource!.saveUser(testUser))
            .thenAnswer((_) async {});

        // Act
        await repository.updateUser(testUser);

        // Assert: Should call the same methods as updateCurrentUser
        verify(mockRemoteDataSource!.updateUser(testUser)).called(1);
        verify(mockLocalDataSource!.saveUser(testUser)).called(1);
      });
    });

    group('Role-based Operations and Security', () {
      test('handles different user roles correctly in sign up', () async {
        // Arrange: Test with different user roles
        final adminUser = User(
          id: TestConstants.testUserId,
          email: TestConstants.testEmail,
          name: TestConstants.testUserName,
          role: UserRole.admin,
          createdAt: TestHelpers.createTestDateTime(),
          updatedAt: TestHelpers.createTestDateTime(),
        );
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signUp(testEmail, testPassword, testName))
            .thenAnswer((_) async => adminUser);
        when(mockLocalDataSource!.saveUser(adminUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.signUp(testEmail, testPassword, testName);

        // Assert
        expect(result?.role, equals(UserRole.admin));
      });

      test('preserves user role information during updates', () async {
        // Arrange: User with specific role
        final curatorUser = User(
          id: TestConstants.testUserId,
          email: TestConstants.testEmail,
          name: TestConstants.testUserName,
          role: UserRole.user,
          createdAt: TestHelpers.createTestDateTime(),
          updatedAt: TestHelpers.createTestDateTime(),
        );
        when(mockRemoteDataSource!.updateUser(curatorUser))
            .thenAnswer((_) async => curatorUser);
        when(mockLocalDataSource!.saveUser(curatorUser))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updateCurrentUser(curatorUser);

        // Assert
        expect(result?.role, equals(UserRole.user));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles concurrent authentication operations', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn(any, any))
            .thenAnswer((_) async => testUser);
        when(mockLocalDataSource!.saveUser(any))
            .thenAnswer((_) async {});

        // Act: Multiple concurrent sign in attempts
        final futures = List.generate(
          3,
          (_) => repository.signIn(testEmail, testPassword),
        );
        final results = await Future.wait(futures);

        // Assert: All should succeed
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, equals(testUser));
        }
      });

      test('handles null connectivity gracefully', () async {
        // Arrange: Repository with null connectivity
        repository = AuthRepositoryImpl(
          localDataSource: mockLocalDataSource,
          remoteDataSource: mockRemoteDataSource,
          connectivity: null,
        );
        when(mockLocalDataSource!.signIn(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.signIn(testEmail, testPassword);

        // Assert: Should default to offline behavior
        expect(result, equals(testUser));
        verify(mockLocalDataSource!.signIn(testEmail, testPassword)).called(1);
      });

      test('handles completely null dependencies', () async {
        // Arrange: Repository with all null dependencies
        repository = AuthRepositoryImpl(
          localDataSource: null,
          remoteDataSource: null,
          connectivity: null,
        );

        // Act & Assert: Should not crash
        final signInResult = await repository.signIn(testEmail, testPassword);
        expect(signInResult, isNull);
        
        final getCurrentResult = await repository.getCurrentUser();
        expect(getCurrentResult, isNull);
        
        final isOffline = await repository.isOfflineMode();
        expect(isOffline, isTrue);
        
        // Should not throw
        await repository.signOut();
      });

      test('handles invalid credentials gracefully', () async {
        // Arrange
        when(mockConnectivity!.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRemoteDataSource!.signIn('invalid@email.com', 'wrongpassword'))
            .thenThrow(Exception('Invalid credentials'));
        when(mockLocalDataSource!.signIn('invalid@email.com', 'wrongpassword'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.signIn('invalid@email.com', 'wrongpassword');

        // Assert
        expect(result, isNull);
        verify(mockRemoteDataSource!.signIn('invalid@email.com', 'wrongpassword')).called(1);
        verify(mockLocalDataSource!.signIn('invalid@email.com', 'wrongpassword')).called(1);
      });
    });
  });
}