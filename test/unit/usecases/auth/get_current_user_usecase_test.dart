import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/user.dart' as app_user;
import 'package:spots/domain/repositories/auth_repository.dart';
import 'package:spots/domain/usecases/auth/get_current_user_usecase.dart';

import 'get_current_user_usecase_test.mocks.dart';

// Generate mocks
@GenerateMocks([AuthRepository])
void main() {
  group('GetCurrentUserUseCase', () {
    late GetCurrentUserUseCase usecase;
    late MockAuthRepository mockRepository;
    late app_user.User testUser;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = GetCurrentUserUseCase(mockRepository);
      
      testUser = app_user.User(
        id: 'current_user_123',
        email: 'current@example.com',
        name: 'Current User',
        displayName: 'Current Display',
        role: app_user.UserRole.user,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
        isOnline: true,
      );
    });

    group('Successful user retrieval', () {
      test('should return current user successfully when authenticated', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(testUser));
        expect(result!.id, equals('current_user_123'));
        expect(result.email, equals('current@example.com'));
        expect(result.name, equals('Current User'));
        expect(result.role, equals(app_user.UserRole.user));
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should return user with all properties intact', () async {
        // Arrange
        final complexUser = app_user.User(
          id: 'complex_current_user',
          email: 'complex.user@domain.co.uk',
          name: 'Complex User Name',
          displayName: 'Complex Display Name',
          role: app_user.UserRole.moderator,
          createdAt: DateTime(2023, 6, 15, 14, 30, 45),
          updatedAt: DateTime(2024, 1, 20, 9, 15, 30),
          isOnline: false,
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => complexUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(complexUser));
        expect(result!.id, equals('complex_current_user'));
        expect(result.email, equals('complex.user@domain.co.uk'));
        expect(result.name, equals('Complex User Name'));
        expect(result.displayName, equals('Complex Display Name'));
        expect(result.role, equals(app_user.UserRole.moderator));
        expect(result.createdAt, equals(DateTime(2023, 6, 15, 14, 30, 45)));
        expect(result.updatedAt, equals(DateTime(2024, 1, 20, 9, 15, 30)));
        expect(result.isOnline, isFalse);
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should return users with different roles', () async {
        // Arrange & Act & Assert
        for (final role in app_user.UserRole.values) {
          final userWithRole = testUser.copyWith(
            role: role,
            id: 'user_${role.name}',
          );

          when(mockRepository.getCurrentUser())
              .thenAnswer((_) async => userWithRole);

          final result = await usecase.call();

          expect(result, isNotNull);
          expect(result!.role, equals(role));
          verify(mockRepository.getCurrentUser()).called(1);
        }
      });

      test('should return user with null optional fields', () async {
        // Arrange
        final userWithNulls = app_user.User(
          id: 'user_with_nulls',
          email: 'null.fields@example.com',
          name: 'User With Nulls',
          displayName: null, // Null display name
          role: app_user.UserRole.user,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isOnline: null, // Null online status
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => userWithNulls);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(userWithNulls));
        expect(result!.displayName, isNull);
        expect(result.isOnline, isNull);
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should return user with various online states', () async {
        // Arrange & Act & Assert
        final onlineStates = [true, false, null];
        
        for (final isOnline in onlineStates) {
          final userWithState = testUser.copyWith(
            isOnline: isOnline,
            id: 'user_online_${isOnline?.toString() ?? 'null'}',
          );

          when(mockRepository.getCurrentUser())
              .thenAnswer((_) async => userWithState);

          final result = await usecase.call();

          expect(result, isNotNull);
          expect(result!.isOnline, equals(isOnline));
          verify(mockRepository.getCurrentUser()).called(1);
        }
      });
    });

    group('No current user scenarios', () {
      test('should return null when no user is authenticated', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should return null when user session expired', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should return null when user was signed out', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCurrentUser()).called(1);
      });
    });

    group('Edge cases and validation', () {
      test('should handle user with empty strings in optional fields', () async {
        // Arrange
        final userWithEmptyStrings = app_user.User(
          id: 'user_empty_strings',
          email: 'empty@example.com',
          name: 'User Name',
          displayName: '', // Empty display name
          role: app_user.UserRole.user,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isOnline: true,
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => userWithEmptyStrings);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(userWithEmptyStrings));
        expect(result!.displayName, equals(''));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle user with very long names', () async {
        // Arrange
        final longName = 'Very' + ' Long' * 100 + ' Name';
        final longDisplayName = 'Very' + ' Long' * 100 + ' Display Name';
        final userWithLongNames = testUser.copyWith(
          name: longName,
          displayName: longDisplayName,
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => userWithLongNames);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(userWithLongNames));
        expect(result!.name, equals(longName));
        expect(result.displayName, equals(longDisplayName));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle user with special characters in names', () async {
        // Arrange
        final specialUser = testUser.copyWith(
          name: r'User @#$%^&*()_+ Name',
          displayName: r'Display !@#$%^&*()_+ Name',
          email: 'special+user@example-domain.co.uk',
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => specialUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(specialUser));
        expect(result!.name, contains(r'@#$%^&*()_+'));
        expect(result.displayName, contains(r'!@#$%^&*()_+'));
        expect(result.email, contains('+'));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle user with unicode characters', () async {
        // Arrange
        final unicodeUser = testUser.copyWith(
          name: 'José María García-López',
          displayName: '李明 (Li Ming)',
          email: 'josé.maría@тест.рф',
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => unicodeUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(unicodeUser));
        expect(result!.name, equals('José María García-López'));
        expect(result.displayName, equals('李明 (Li Ming)'));
        expect(result.email, equals('josé.maría@тест.рф'));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle user with extreme timestamps', () async {
        // Arrange
        final extremeUser = testUser.copyWith(
          createdAt: DateTime(1990, 1, 1),
          updatedAt: DateTime(2050, 12, 31),
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => extremeUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(extremeUser));
        expect(result!.createdAt.year, equals(1990));
        expect(result.updatedAt.year, equals(2050));
        verify(mockRepository.getCurrentUser()).called(1);
      });
    });

    group('Error handling', () {
      test('should throw exception when repository throws exception', () async {
        // Arrange
        final exception = Exception('Failed to get current user');
        when(mockRepository.getCurrentUser())
            .thenThrow(exception);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(exception),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle authentication token expired error', () async {
        // Arrange
        final tokenExpiredError = Exception('Authentication token expired');
        when(mockRepository.getCurrentUser())
            .thenThrow(tokenExpiredError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(tokenExpiredError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle network connectivity error', () async {
        // Arrange
        final networkError = Exception('No network connection');
        when(mockRepository.getCurrentUser())
            .thenThrow(networkError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(networkError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle server unavailable error', () async {
        // Arrange
        final serverError = Exception('Server unavailable');
        when(mockRepository.getCurrentUser())
            .thenThrow(serverError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(serverError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle data corruption error', () async {
        // Arrange
        final corruptionError = FormatException('User data corrupted');
        when(mockRepository.getCurrentUser())
            .thenThrow(corruptionError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(corruptionError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle permission denied error', () async {
        // Arrange
        final permissionError = Exception('Permission denied');
        when(mockRepository.getCurrentUser())
            .thenThrow(permissionError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(permissionError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle database connection error', () async {
        // Arrange
        final dbError = Exception('Database connection failed');
        when(mockRepository.getCurrentUser())
            .thenThrow(dbError);

        // Act & Assert
        expect(
          () async => await usecase.call(),
          throwsA(dbError),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });
    });

    group('Business logic validation', () {
      test('should be a simple pass-through to repository', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should not modify user data from repository', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(testUser));
        expect(identical(result, testUser), isTrue); // Same reference
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should not apply any filtering or validation', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should be idempotent - multiple calls return same data', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final result1 = await usecase.call();
        final result2 = await usecase.call();
        final result3 = await usecase.call();

        // Assert
        expect(result1, equals(result2));
        expect(result2, equals(result3));
        verify(mockRepository.getCurrentUser()).called(3);
      });

      test('should handle concurrent calls independently', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final futures = List.generate(5, (_) => usecase.call());
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result, equals(testUser));
        }
        verify(mockRepository.getCurrentUser()).called(5);
      });

      test('should be stateless between calls', () async {
        // Arrange
        final user1 = testUser.copyWith(id: 'user1');
        final user2 = testUser.copyWith(id: 'user2');
        var callCount = 0;

        when(mockRepository.getCurrentUser()).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? user1 : user2;
        });

        // Act
        final result1 = await usecase.call();
        final result2 = await usecase.call();

        // Assert
        expect(result1, isNotNull);
        expect(result1!.id, equals('user1'));
        expect(result2, isNotNull);
        expect(result2!.id, equals('user2'));
        verify(mockRepository.getCurrentUser()).called(2);
      });
    });

    group('Caching and performance', () {
      test('should not implement any caching logic', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        await usecase.call();
        await usecase.call();

        // Assert
        // Should call repository each time (no caching)
        verify(mockRepository.getCurrentUser()).called(2);
      });

      test('should complete quickly for successful retrieval', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);

        // Act
        final start = DateTime.now();
        final result = await usecase.call();
        final duration = DateTime.now().difference(start);

        // Assert
        expect(result, equals(testUser));
        expect(duration.inMilliseconds, lessThan(100));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle delayed repository response', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async {
              await Future.delayed(Duration(milliseconds: 200));
              return testUser;
            });

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.getCurrentUser()).called(1);
      });
    });

    group('User state scenarios', () {
      test('should handle newly created user', () async {
        // Arrange
        final now = DateTime.now();
        final newUser = testUser.copyWith(
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => newUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(newUser));
        expect(result!.createdAt, equals(result.updatedAt));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle user with recent updates', () async {
        // Arrange
        final recentlyUpdatedUser = testUser.copyWith(
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => recentlyUpdatedUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result, equals(recentlyUpdatedUser));
        expect(result!.updatedAt.isAfter(result.createdAt), isTrue);
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle admin user', () async {
        // Arrange
        final adminUser = testUser.copyWith(role: app_user.UserRole.admin);

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => adminUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result!.role, equals(app_user.UserRole.admin));
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('should handle moderator user', () async {
        // Arrange
        final moderatorUser = testUser.copyWith(role: app_user.UserRole.moderator);

        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => moderatorUser);

        // Act
        final result = await usecase.call();

        // Assert
        expect(result!.role, equals(app_user.UserRole.moderator));
        verify(mockRepository.getCurrentUser()).called(1);
      });
    });
  });
}
