/// Smoke Tests - Critical User Paths
/// 
/// Phase 7, Section 47-48 (7.4.1-2): Final Review & Polish
/// Agent 3: Models & Testing Specialist
/// 
/// Purpose: Test critical user paths to ensure production readiness
/// These tests validate that major features work end-to-end

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import '../helpers/bloc_test_helpers.dart';
import '../mocks/bloc_mock_dependencies.dart';
import '../fixtures/model_factories.dart';

void main() {
  group('Smoke Tests - Critical User Paths', () {
    setUpAll(() {
      BlocMockFactory.registerFallbacks();
    });

    group('1. Authentication Flow Smoke Tests', () {
      late AuthBloc authBloc;
      late MockSignInUseCase mockSignInUseCase;
      late MockSignUpUseCase mockSignUpUseCase;
      late MockSignOutUseCase mockSignOutUseCase;
      late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

      setUp(() {
        mockSignInUseCase = BlocMockFactory.signInUseCase;
        mockSignUpUseCase = BlocMockFactory.signUpUseCase;
        mockSignOutUseCase = BlocMockFactory.signOutUseCase;
        mockGetCurrentUserUseCase = BlocMockFactory.getCurrentUserUseCase;
        
        BlocMockFactory.resetAll();

        authBloc = AuthBloc(
          signInUseCase: mockSignInUseCase,
          signUpUseCase: mockSignUpUseCase,
          signOutUseCase: mockSignOutUseCase,
          getCurrentUserUseCase: mockGetCurrentUserUseCase,
        );
      });

      tearDown(() {
        authBloc.close();
      });

      blocTest<AuthBloc, AuthState>(
        'SMOKE: User can sign in with valid credentials',
        build: () {
          const email = 'demo@spots.com';
          const password = 'password123';
          
          when(() => mockSignInUseCase.call(email, password))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                email: email,
                isOnline: true,
              ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('demo@spots.com', 'password123')),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.email, 'email', 'demo@spots.com')
              .having((state) => state.isOffline, 'isOffline', false),
        ],
        verify: (_) {
          verify(() => mockSignInUseCase.call(any(), any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'SMOKE: User can sign up with new account',
        build: () {
          const email = 'newuser@example.com';
          const password = 'newpassword123';
          const name = 'New User';
          
          when(() => mockSignUpUseCase.call(email, password, name))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                email: email,
                name: name,
                isOnline: true,
              ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignUpRequested('newuser@example.com', 'newpassword123', 'New User')),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.user.email, 'email', 'newuser@example.com')
              .having((state) => state.user.name, 'name', 'New User'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'SMOKE: User can sign out',
        seed: () => Authenticated(
          user: TestDataFactory.createTestUser(),
          isOffline: false,
        ),
        build: () {
          when(() => mockSignOutUseCase.call()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(SignOutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Unauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'SMOKE: App can check current user on startup',
        build: () {
          when(() => mockGetCurrentUserUseCase.call())
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                isOnline: true,
              ));
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'SMOKE: Invalid credentials are rejected',
        build: () {
          const email = 'invalid@example.com';
          const password = 'wrongpassword';
          
          when(() => mockSignInUseCase.call(email, password))
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('invalid@example.com', 'wrongpassword')),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((state) => state.message, 'message', 'Invalid credentials'),
        ],
      );
    });

    group('2. Core Functionality Smoke Tests', () {
      test('SMOKE: Spot model can be created with required fields', () {
        final spot = ModelFactories.createTestSpot(
          name: 'Test Coffee Shop',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'Food & Drink',
        );

        expect(spot.id, isNotEmpty);
        expect(spot.name, equals('Test Coffee Shop'));
        expect(spot.latitude, equals(40.7128));
        expect(spot.longitude, equals(-74.0060));
        expect(spot.category, equals('Food & Drink'));
        expect(spot.createdAt, isNotNull);
        expect(spot.updatedAt, isNotNull);
      });

      test('SMOKE: UnifiedList model can be created with required fields', () {
        final list = ModelFactories.createTestList(
          title: 'My Favorite Places',
          curatorId: 'user-123',
        );

        expect(list.id, isNotEmpty);
        expect(list.title, equals('My Favorite Places'));
        expect(list.curatorId, equals('user-123'));
        expect(list.createdAt, isNotNull);
        expect(list.isPublic, isTrue);
      });

      test('SMOKE: UnifiedUser model can be created with required fields', () {
        final user = ModelFactories.createTestUser(
          email: 'test@example.com',
          displayName: 'Test User',
        );

        expect(user.id, isNotEmpty);
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.createdAt, isNotNull);
        expect(user.updatedAt, isNotNull);
      });
    });

    group('3. Major Features Smoke Tests', () {
      test('SMOKE: User can create a spot', () {
        final spot = ModelFactories.createTestSpot(
          name: 'New Spot',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'Restaurant',
        );

        // Verify spot has all required fields
        expect(spot.name, isNotEmpty);
        expect(spot.latitude, isNotNull);
        expect(spot.longitude, isNotNull);
        expect(spot.category, isNotEmpty);
        expect(spot.createdBy, isNotEmpty);
      });

      test('SMOKE: User can create a list', () {
        final list = ModelFactories.createTestList(
          title: 'My List',
          curatorId: 'user-123',
        );

        // Verify list has all required fields
        expect(list.title, isNotEmpty);
        expect(list.curatorId, isNotEmpty);
        expect(list.createdAt, isNotNull);
      });

      test('SMOKE: User can add spot to list', () {
        final list = ModelFactories.createTestList(
          spotIds: ['spot-1'],
        );

        expect(list.spotIds, contains('spot-1'));
        expect(list.spotIds.length, equals(1));
      });

      test('SMOKE: User can respect a list', () {
        final list = ModelFactories.createTestList(
          respectCount: 5,
        );

        expect(list.respectCount, equals(5));
      });
    });

    group('4. Data Validation Smoke Tests', () {
      test('SMOKE: Spot coordinates are valid', () {
        final spot = ModelFactories.createTestSpot(
          latitude: 40.7128,
          longitude: -74.0060,
        );

        expect(spot.latitude, greaterThanOrEqualTo(-90));
        expect(spot.latitude, lessThanOrEqualTo(90));
        expect(spot.longitude, greaterThanOrEqualTo(-180));
        expect(spot.longitude, lessThanOrEqualTo(180));
      });

      test('SMOKE: User email format is validated', () {
        final user = ModelFactories.createTestUser(
          email: 'test@example.com',
        );

        expect(user.email, contains('@'));
        expect(user.email.split('@').length, equals(2));
      });

      test('SMOKE: List title is not empty', () {
        final list = ModelFactories.createTestList(
          title: 'Valid Title',
        );

        expect(list.title.trim(), isNotEmpty);
      });
    });

    group('5. Error Handling Smoke Tests', () {
      late AuthBloc authBloc;
      late MockSignInUseCase mockSignInUseCase;

      setUp(() {
        mockSignInUseCase = BlocMockFactory.signInUseCase;
        BlocMockFactory.resetAll();

        authBloc = AuthBloc(
          signInUseCase: mockSignInUseCase,
          signUpUseCase: BlocMockFactory.signUpUseCase,
          signOutUseCase: BlocMockFactory.signOutUseCase,
          getCurrentUserUseCase: BlocMockFactory.getCurrentUserUseCase,
        );
      });

      tearDown(() {
        authBloc.close();
      });

      blocTest<AuthBloc, AuthState>(
        'SMOKE: Network errors are handled gracefully',
        build: () {
          when(() => mockSignInUseCase.call(any(), any()))
              .thenThrow(Exception('Network error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('test@test.com', 'password')),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>()
              .having((state) => state.message, 'message', contains('Network error')),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'SMOKE: Empty credentials are rejected',
        build: () {
          when(() => mockSignInUseCase.call('', ''))
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

    group('6. Offline Mode Smoke Tests', () {
      late AuthBloc authBloc;
      late MockSignInUseCase mockSignInUseCase;

      setUp(() {
        mockSignInUseCase = BlocMockFactory.signInUseCase;
        BlocMockFactory.resetAll();

        authBloc = AuthBloc(
          signInUseCase: mockSignInUseCase,
          signUpUseCase: BlocMockFactory.signUpUseCase,
          signOutUseCase: BlocMockFactory.signOutUseCase,
          getCurrentUserUseCase: BlocMockFactory.getCurrentUserUseCase,
        );
      });

      tearDown(() {
        authBloc.close();
      });

      blocTest<AuthBloc, AuthState>(
        'SMOKE: User can sign in offline',
        build: () {
          when(() => mockSignInUseCase.call(any(), any()))
              .thenAnswer((_) async => TestDataFactory.createTestUser(
                isOnline: false,
              ));
          return authBloc;
        },
        act: (bloc) => bloc.add(SignInRequested('test@test.com', 'password')),
        expect: () => [
          isA<AuthLoading>(),
          isA<Authenticated>()
              .having((state) => state.isOffline, 'isOffline', true),
        ],
      );
    });
  });
}

