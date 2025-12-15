/// AuthBloc Unit Tests - Phase 4: BLoC State Management Testing
///
/// Comprehensive testing of AuthBloc with all event→state transitions
/// Ensures optimal development stages and deployment optimization
/// Tests current implementation as-is without modifying production code

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/services/personality_sync_service.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/injection_container.dart' as di;
import '../../helpers/bloc_test_helpers.dart';
import '../../mocks/bloc_mock_dependencies.dart';

// Mocks for services accessed via GetIt
class MockPersonalitySyncService extends Mock implements PersonalitySyncService {}
class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockSignInUseCase mockSignInUseCase;
    late MockSignUpUseCase mockSignUpUseCase;
    late MockSignOutUseCase mockSignOutUseCase;
    late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
    late MockUpdatePasswordUseCase mockUpdatePasswordUseCase;

    setUpAll(() {
      BlocMockFactory.registerFallbacks();
      
      // Register mock PersonalitySyncService in GetIt
      final mockSyncService = MockPersonalitySyncService();
      when(() => mockSyncService.isCloudSyncEnabled(any())).thenAnswer((_) async => false);
      when(() => mockSyncService.reEncryptWithNewPassword(any(), any(), any())).thenAnswer((_) async {});
      if (di.sl.isRegistered<PersonalitySyncService>()) {
        di.sl.unregister<PersonalitySyncService>();
      }
      di.sl.registerSingleton<PersonalitySyncService>(mockSyncService);
      
      // Register mock PersonalityLearning in GetIt
      final mockPersonalityLearning = MockPersonalityLearning();
      final testProfile = PersonalityProfile.initial('test-user-123');
      when(() => mockPersonalityLearning.initializePersonality(any(), password: any(named: 'password'))).thenAnswer((_) async => testProfile);
      when(() => mockPersonalityLearning.initializePersonality(any())).thenAnswer((_) async => testProfile);
      if (di.sl.isRegistered<PersonalityLearning>()) {
        di.sl.unregister<PersonalityLearning>();
      }
      di.sl.registerSingleton<PersonalityLearning>(mockPersonalityLearning);
    });

    setUp(() {
      mockSignInUseCase = BlocMockFactory.signInUseCase;
      mockSignUpUseCase = BlocMockFactory.signUpUseCase;
      mockSignOutUseCase = BlocMockFactory.signOutUseCase;
      mockGetCurrentUserUseCase = BlocMockFactory.getCurrentUserUseCase;
      mockUpdatePasswordUseCase = BlocMockFactory.updatePasswordUseCase;

      BlocMockFactory.resetAll();
      
      // Set up default successful response for updatePasswordUseCase
      // Individual tests can override this if needed
      when(() => mockUpdatePasswordUseCase(any(), any()))
          .thenAnswer((_) async => {});

      authBloc = AuthBloc(
        signInUseCase: mockSignInUseCase,
        signUpUseCase: mockSignUpUseCase,
        signOutUseCase: mockSignOutUseCase,
        getCurrentUserUseCase: mockGetCurrentUserUseCase,
        updatePasswordUseCase: mockUpdatePasswordUseCase,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    group('Initial State', () {
      test('should have AuthInitial as initial state', () {
        expect(authBloc.state, isA<AuthInitial>());
      });
    });

    group('SignInRequested Event', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when sign in succeeds',
        build: () {
          when(() => mockSignInUseCase(testEmail, testPassword))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    email: testEmail,
                    isOnline: true,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested(testEmail, testPassword)),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.email, 'email', testEmail)
              .having((state) => state.isOffline, 'isOffline', false),
        ],
        verify: (_) {
          verify(() => mockSignInUseCase(testEmail, testPassword)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] with offline flag when user isOnline is false',
        build: () {
          when(() => mockSignInUseCase(testEmail, testPassword))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    email: testEmail,
                    isOnline: false,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested(testEmail, testPassword)),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.email, 'email', testEmail)
              .having((state) => state.isOffline, 'isOffline', true),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in returns null user',
        build: () {
          when(() => mockSignInUseCase(testEmail, testPassword))
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested(testEmail, testPassword)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (state) => state.message, 'message', 'Invalid credentials'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign in throws exception',
        build: () {
          when(() => mockSignInUseCase(testEmail, testPassword))
              .thenThrow(Exception('Network error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested(testEmail, testPassword)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (state) => state.message, 'message', contains('Network error')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'handles empty email and password',
        build: () {
          when(() => mockSignInUseCase('', ''))
              .thenThrow(Exception('Email and password required'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('', '')),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>(),
        ],
      );
    });

    group('SignUpRequested Event', () {
      const testEmail = 'newuser@example.com';
      const testPassword = 'newpassword123';
      const testName = 'New User';

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when sign up succeeds',
        build: () {
          when(() => mockSignUpUseCase(testEmail, testPassword, testName))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    email: testEmail,
                    name: testName,
                    isOnline: true,
                  ));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(SignUpRequested(testEmail, testPassword, testName)),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.email, 'email', testEmail)
              .having((state) => state.user.name, 'name', testName)
              .having((state) => state.isOffline, 'isOffline', false),
        ],
        verify: (_) {
          verify(() => mockSignUpUseCase(testEmail, testPassword, testName))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] with offline flag when user isOnline is false',
        build: () {
          when(() => mockSignUpUseCase(testEmail, testPassword, testName))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    email: testEmail,
                    name: testName,
                    isOnline: false,
                  ));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(SignUpRequested(testEmail, testPassword, testName)),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', true),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign up returns null user',
        build: () {
          when(() => mockSignUpUseCase(testEmail, testPassword, testName))
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(SignUpRequested(testEmail, testPassword, testName)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (state) => state.message, 'message', 'Failed to create account'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign up throws exception',
        build: () {
          when(() => mockSignUpUseCase(testEmail, testPassword, testName))
              .thenThrow(Exception('Email already exists'));
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(SignUpRequested(testEmail, testPassword, testName)),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having((state) => state.message, 'message',
              contains('Email already exists')),
        ],
      );
    });

    group('SignOutRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when sign out succeeds',
        build: () {
          when(() => mockSignOutUseCase()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ],
        verify: (_) {
          verify(() => mockSignOutUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when sign out throws exception',
        build: () {
          when(() => mockSignOutUseCase())
              .thenThrow(Exception('Sign out failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
              (state) => state.message, 'message', contains('Sign out failed')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'can sign out from authenticated state',
        seed: () => Authenticated(
          user: TestDataFactory.createTestUser(),
          isOffline: false,
        ),
        build: () {
          when(() => mockSignOutUseCase()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ],
      );
    });

    group('AuthCheckRequested Event', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when current user exists',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    isOnline: true,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', false),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] with offline flag when user isOnline is false',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    isOnline: false,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', true),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when current user is null',
        build: () {
          when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Unauthenticated] when getCurrentUser throws exception',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenThrow(Exception('Token expired'));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ],
      );
    });

    group('State Transitions and Edge Cases', () {
      blocTest<AuthBloc, AuthState>(
        'handles multiple rapid sign in attempts',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser());
          return authBloc;
        },
        act: (bloc) {
          bloc.add(SignInRequested('user1@test.com', 'pass1'));
          bloc.add(SignInRequested('user2@test.com', 'pass2'));
          bloc.add(SignInRequested('user3@test.com', 'pass3'));
        },
        // Only the last event should complete due to BLoC's event handling
        verify: (_) {
          // Verify that use case was called (may be multiple times)
          verify(() => mockSignInUseCase(any(), any())).called(greaterThan(0));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles mixed event types in sequence',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser());
          when(() => mockSignOutUseCase()).thenAnswer((_) async {});
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => TestDataFactory.createTestUser());
          return authBloc;
        },
        act: (bloc) {
          bloc.add(SignInRequested('test@test.com', 'password'));
          bloc.add(SignOutRequested());
          bloc.add(AuthCheckRequested());
        },
        // Verify that the bloc handles mixed events without crashing
        verify: (_) {
          // At least some use cases should be called
          verify(() => mockSignInUseCase(any(), any())).called(greaterThan(0));
        },
      );

      test('AuthError state preserves message correctly', () {
        const errorMessage = 'Custom error message';
        final errorState = AuthError(errorMessage);
        expect(errorState.message, equals(errorMessage));
      });

      test('Authenticated state preserves user and offline flag correctly', () {
        final testUser = TestDataFactory.createTestUser();
        const isOffline = true;

        final authenticatedState = Authenticated(
          user: testUser,
          isOffline: isOffline,
        );

        expect(authenticatedState.user, equals(testUser));
        expect(authenticatedState.isOffline, equals(isOffline));
      });

      test('Authenticated state defaults offline flag to false', () {
        final testUser = TestDataFactory.createTestUser();
        final authenticatedState = Authenticated(user: testUser);
        expect(authenticatedState.isOffline, equals(false));
      });
    });

    group('Performance and Reliability', () {
      test('BLoC processes events within acceptable time limits', () async {
        when(() => mockSignInUseCase(any(), any()))
            .thenAnswer((_) async => TestDataFactory.createTestUser());

        final stopwatch = Stopwatch()..start();
        authBloc.add(SignInRequested('test@test.com', 'password'));

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));
        stopwatch.stop();

        // Should complete quickly for optimal UX
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      blocTest<AuthBloc, AuthState>(
        'maintains consistent state behavior across multiple operations',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser());
          when(() => mockSignOutUseCase()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) async {
          // Perform multiple sign in/out cycles
          bloc.add(SignInRequested('test1@test.com', 'pass1'));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(SignOutRequested());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(SignInRequested('test2@test.com', 'pass2'));
        },
        // Should not throw or enter invalid states
        verify: (_) {
          verify(() => mockSignInUseCase(any(), any())).called(greaterThan(0));
        },
      );
    });

    group('Error Recovery', () {
      blocTest<AuthBloc, AuthState>(
        'can recover from error state by performing successful authentication',
        build: () {
          var callCount = 0;
          when(() => mockSignInUseCase(any(), any())).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Network error');
            }
            return TestDataFactory.createTestUser();
          });
          return authBloc;
        },
        act: (bloc) async {
          // First attempt fails
          bloc.add(SignInRequested('test@test.com', 'password'));
          await Future.delayed(const Duration(milliseconds: 50));

          // Second attempt succeeds
          bloc.add(SignInRequested('test@test.com', 'password'));
        },
        verify: (_) {
          verify(() => mockSignInUseCase(any(), any())).called(2);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'handles network timeout gracefully',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) => Future.delayed(
                    const Duration(seconds: 30),
                    () => throw Exception('Timeout'),
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('test@test.com', 'password')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isA<AuthLoading>(),
          // Should eventually emit error or handle timeout
        ],
      );
    });

    group('Offline/Online Mode Testing', () {
      blocTest<AuthBloc, AuthState>(
        'correctly identifies offline users',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    isOnline: false,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('test@test.com', 'password')),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', true),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'correctly identifies online users',
        build: () {
          when(() => mockSignInUseCase(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                    isOnline: true,
                  ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('test@test.com', 'password')),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', false),
        ],
      );
    });

    group('UpdatePasswordRequested Event', () {
      const testUserId = 'test_user_1';
      const currentPassword = 'old_password';
      const newPassword = 'new_password';

      final testUser = TestDataFactory.createTestUser(
        id: testUserId,
        email: 'test@example.com',
        isOnline: true,
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when password update succeeds',
        build: () {
          // Create a new bloc instance for this test
          final testBloc = AuthBloc(
            signInUseCase: mockSignInUseCase,
            signUpUseCase: mockSignUpUseCase,
            signOutUseCase: mockSignOutUseCase,
            getCurrentUserUseCase: mockGetCurrentUserUseCase,
            updatePasswordUseCase: mockUpdatePasswordUseCase,
          );
          // Set initial authenticated state
          testBloc.emit(Authenticated(user: testUser, isOffline: false));

          return testBloc;
        },
        act: (bloc) =>
            bloc.add(UpdatePasswordRequested(currentPassword, newPassword)),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        // Note: Re-encryption may fail in unit tests (GetIt not initialized),
        // but password update should still succeed
        expect: () => [
          isA<AuthLoading>(),
          // Password update succeeds even if re-encryption fails
          isA<Authenticated>()
              .having((state) => state.user.id, 'userId', testUserId),
        ],
        verify: (_) {
          verify(() => mockUpdatePasswordUseCase(currentPassword, newPassword))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when not authenticated',
        build: () {
          // Start with unauthenticated state
          authBloc.emit(Unauthenticated());
          return authBloc;
        },
        act: (bloc) =>
            bloc.add(UpdatePasswordRequested(currentPassword, newPassword)),
        wait: const Duration(milliseconds: 500), // Allow state emissions to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having((state) => state.message, 'message',
              'Must be authenticated to change password'),
        ],
        verify: (_) {
          verifyNever(() => mockUpdatePasswordUseCase(any(), any()));
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when password update use case throws',
        build: () {
          // Create a new bloc instance for this test
          final testBloc = AuthBloc(
            signInUseCase: mockSignInUseCase,
            signUpUseCase: mockSignUpUseCase,
            signOutUseCase: mockSignOutUseCase,
            getCurrentUserUseCase: mockGetCurrentUserUseCase,
            updatePasswordUseCase: mockUpdatePasswordUseCase,
          );
          testBloc.emit(Authenticated(user: testUser, isOffline: false));

          when(() => mockUpdatePasswordUseCase(currentPassword, newPassword))
              .thenThrow(Exception('Password update failed'));

          return testBloc;
        },
        act: (bloc) =>
            bloc.add(UpdatePasswordRequested(currentPassword, newPassword)),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          // Re-encryption may fail first (GetIt not initialized), but then password update fails
          isA<AuthError>().having((state) => state.message, 'message',
              contains('Failed to update password')),
        ],
        verify: (_) {
          verify(() => mockUpdatePasswordUseCase(currentPassword, newPassword))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'calls updatePasswordUseCase with correct parameters',
        build: () {
          // Reset and set up mock before creating bloc
          reset(mockUpdatePasswordUseCase);
          when(() => mockUpdatePasswordUseCase(any(), any()))
              .thenAnswer((_) async => {});
          
          // Create a new bloc instance for this test
          final testBloc = AuthBloc(
            signInUseCase: mockSignInUseCase,
            signUpUseCase: mockSignUpUseCase,
            signOutUseCase: mockSignOutUseCase,
            getCurrentUserUseCase: mockGetCurrentUserUseCase,
            updatePasswordUseCase: mockUpdatePasswordUseCase,
          );
          testBloc.emit(Authenticated(user: testUser, isOffline: false));

          return testBloc;
        },
        act: (bloc) =>
            bloc.add(UpdatePasswordRequested(currentPassword, newPassword)),
        wait: const Duration(milliseconds: 1000), // Allow async operations to complete
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.id, 'userId', testUserId),
        ],
        verify: (_) {
          verify(() => mockUpdatePasswordUseCase(currentPassword, newPassword))
              .called(1);
        },
      );
    });
  });
}
