import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';
import 'package:spots/domain/usecases/auth/sign_in_usecase.dart';

import 'sign_in_usecase_test.mocks.dart';

// Generate mocks
@GenerateMocks([AuthRepository])
void main() {
  group('SignInUseCase', () {
    late SignInUseCase usecase;
    late MockAuthRepository mockRepository;
    late User testUser;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = SignInUseCase(mockRepository);
      
      testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        name: 'Test User',
        displayName: 'Test Display',
        role: UserRole.user,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isOnline: true,
      );
    });

    group('Successful sign in', () {
      test('should sign in user successfully with valid credentials', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'validPassword123';
        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, equals(testUser));
        expect(result!.email, equals(email));
        expect(result.name, equals('Test User'));
        expect(result.role, equals(UserRole.user));
        verify(mockRepository.signIn(email, password)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should sign in user with different email formats', () async {
        // Arrange
        final emailFormats = [
          'simple@example.com',
          'user.name@example.com',
          'user+tag@example.com',
          'user_name@example-domain.com',
          'UPPERCASE@DOMAIN.COM',
        ];

        for (final email in emailFormats) {
          final userForEmail = testUser.copyWith(
            email: email,
            id: 'user_${email.hashCode}',
          );

          when(mockRepository.signIn(email, 'password'))
              .thenAnswer((_) async => userForEmail);

          // Act
          final result = await usecase.call(email, 'password');

          // Assert
          expect(result, isNotNull);
          expect(result!.email, equals(email));
          verify(mockRepository.signIn(email, 'password')).called(1);
        }
      });

      test('should sign in user with different password types', () async {
        // Arrange
        const email = 'test@example.com';
        final passwords = [
          'shortpwd',
          'verylongpasswordwithmanycharacters123!@#',
          'P@ssw0rd!',
          '12345678',
          'password with spaces',
          'пароль', // Cyrillic
          'パスワード', // Japanese
        ];

        for (final password in passwords) {
          when(mockRepository.signIn(email, password))
              .thenAnswer((_) async => testUser);

          // Act
          final result = await usecase.call(email, password);

          // Assert
          expect(result, equals(testUser));
          verify(mockRepository.signIn(email, password)).called(1);
        }
      });

      test('should sign in users with different roles', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';

        for (final role in UserRole.values) {
          final userWithRole = testUser.copyWith(
            role: role,
            id: 'user_${role.name}',
          );

          when(mockRepository.signIn(email, password))
              .thenAnswer((_) async => userWithRole);

          // Act
          final result = await usecase.call(email, password);

          // Assert
          expect(result, isNotNull);
          expect(result!.role, equals(role));
          verify(mockRepository.signIn(email, password)).called(1);
        }
      });

      test('should preserve all user properties during sign in', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final complexUser = User(
          id: 'complex_user_123',
          email: email,
          name: 'Complex User Name',
          displayName: 'Complex Display Name',
          role: UserRole.moderator,
          createdAt: DateTime(2023, 6, 15, 14, 30),
          updatedAt: DateTime(2024, 1, 20, 9, 45),
          isOnline: false,
        );

        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => complexUser);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, equals(complexUser));
        expect(result!.id, equals('complex_user_123'));
        expect(result.email, equals(email));
        expect(result.name, equals('Complex User Name'));
        expect(result.displayName, equals('Complex Display Name'));
        expect(result.role, equals(UserRole.moderator));
        expect(result.createdAt, equals(DateTime(2023, 6, 15, 14, 30)));
        expect(result.updatedAt, equals(DateTime(2024, 1, 20, 9, 45)));
        expect(result.isOnline, isFalse);
        verify(mockRepository.signIn(email, password)).called(1);
      });
    });

    group('Failed sign in scenarios', () {
      test('should return null for invalid credentials', () async {
        // Arrange
        const email = 'wrong@example.com';
        const password = 'wrongPassword';
        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should return null for non-existent user', () async {
        // Arrange
        const email = 'nonexistent@example.com';
        const password = 'anyPassword';
        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should return null for correct email but wrong password', () async {
        // Arrange
        const email = 'test@example.com';
        const wrongPassword = 'wrongPassword';
        when(mockRepository.signIn(email, wrongPassword))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, wrongPassword);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(email, wrongPassword)).called(1);
      });

      test('should return null for wrong email but any password', () async {
        // Arrange
        const wrongEmail = 'wrong@example.com';
        const password = 'anyPassword';
        when(mockRepository.signIn(wrongEmail, password))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(wrongEmail, password);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(wrongEmail, password)).called(1);
      });
    });

    group('Edge cases and validation', () {
      test('should handle empty email', () async {
        // Arrange
        const emptyEmail = '';
        const password = 'password';
        when(mockRepository.signIn(emptyEmail, password))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(emptyEmail, password);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(emptyEmail, password)).called(1);
      });

      test('should handle empty password', () async {
        // Arrange
        const email = 'test@example.com';
        const emptyPassword = '';
        when(mockRepository.signIn(email, emptyPassword))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, emptyPassword);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(email, emptyPassword)).called(1);
      });

      test('should handle both empty email and password', () async {
        // Arrange
        const emptyEmail = '';
        const emptyPassword = '';
        when(mockRepository.signIn(emptyEmail, emptyPassword))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(emptyEmail, emptyPassword);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signIn(emptyEmail, emptyPassword)).called(1);
      });

      test('should handle email with whitespace', () async {
        // Arrange
        const emailWithSpaces = '  test@example.com  ';
        const password = 'password';
        when(mockRepository.signIn(emailWithSpaces, password))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(emailWithSpaces, password);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(emailWithSpaces, password)).called(1);
      });

      test('should handle password with whitespace', () async {
        // Arrange
        const email = 'test@example.com';
        const passwordWithSpaces = '  password  ';
        when(mockRepository.signIn(email, passwordWithSpaces))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, passwordWithSpaces);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(email, passwordWithSpaces)).called(1);
      });

      test('should handle special characters in email', () async {
        // Arrange
        const specialEmail = 'test+special@example-domain.co.uk';
        const password = 'password';
        when(mockRepository.signIn(specialEmail, password))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(specialEmail, password);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(specialEmail, password)).called(1);
      });

      test('should handle special characters in password', () async {
        // Arrange
        const email = 'test@example.com';
        const specialPassword = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
        when(mockRepository.signIn(email, specialPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, specialPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(email, specialPassword)).called(1);
      });

      test('should handle very long email', () async {
        // Arrange
        final longEmail = '${'a' * 100}@${'example' * 10}.com';
        const password = 'password';
        when(mockRepository.signIn(longEmail, password))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(longEmail, password);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(longEmail, password)).called(1);
      });

      test('should handle very long password', () async {
        // Arrange
        const email = 'test@example.com';
        final longPassword = 'password' * 100;
        when(mockRepository.signIn(email, longPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, longPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(email, longPassword)).called(1);
      });
    });

    group('Error handling', () {
      test('should throw exception when repository throws exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final exception = Exception('Network error');
        when(mockRepository.signIn(email, password))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password),
          throwsA(exception),
        );
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should handle authentication timeout', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final timeoutError = Exception('Authentication timeout');
        when(mockRepository.signIn(email, password))
            .thenThrow(timeoutError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password),
          throwsA(timeoutError),
        );
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should handle server error during sign in', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final serverError = Exception('Internal server error');
        when(mockRepository.signIn(email, password))
            .thenThrow(serverError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password),
          throwsA(serverError),
        );
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should handle account locked exception', () async {
        // Arrange
        const email = 'locked@example.com';
        const password = 'password';
        final lockedException = Exception('Account locked');
        when(mockRepository.signIn(email, password))
            .thenThrow(lockedException);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password),
          throwsA(lockedException),
        );
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should handle rate limiting exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final rateLimitError = Exception('Too many attempts');
        when(mockRepository.signIn(email, password))
            .thenThrow(rateLimitError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password),
          throwsA(rateLimitError),
        );
        verify(mockRepository.signIn(email, password)).called(1);
      });
    });

    group('Business logic validation', () {
      test('should pass email and password exactly as provided', () async {
        // Arrange
        const email = 'EXACT@Example.COM';
        const password = 'ExactPassword123!';
        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, equals(testUser));
        final captured = verify(mockRepository.signIn(captureAny, captureAny)).captured;
        expect(captured[0], equals(email));
        expect(captured[1], equals(password));
      });

      test('should not modify or validate credentials before passing to repository', () async {
        // Arrange
        const rawEmail = '  Raw@Email.com  ';
        const rawPassword = '  RawPassword  ';
        when(mockRepository.signIn(rawEmail, rawPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(rawEmail, rawPassword);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signIn(rawEmail, rawPassword)).called(1);
        // Verify it wasn't trimmed or modified
        verifyNever(mockRepository.signIn(
          argThat(equals(rawEmail.trim())),
          argThat(equals(rawPassword.trim())),
        ));
      });

      test('should handle concurrent sign in attempts', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => testUser);

        // Act
        final futures = List.generate(5, (_) => usecase.call(email, password));
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result, equals(testUser));
        }
        verify(mockRepository.signIn(email, password)).called(5);
      });

      test('should be stateless between calls', () async {
        // Arrange
        const email1 = 'user1@example.com';
        const password1 = 'password1';
        const email2 = 'user2@example.com';
        const password2 = 'password2';

        final user1 = testUser.copyWith(id: 'user1', email: email1);
        final user2 = testUser.copyWith(id: 'user2', email: email2);

        when(mockRepository.signIn(email1, password1))
            .thenAnswer((_) async => user1);
        when(mockRepository.signIn(email2, password2))
            .thenAnswer((_) async => user2);

        // Act
        final result1 = await usecase.call(email1, password1);
        final result2 = await usecase.call(email2, password2);

        // Assert
        expect(result1!.id, equals('user1'));
        expect(result2!.id, equals('user2'));
        verify(mockRepository.signIn(email1, password1)).called(1);
        verify(mockRepository.signIn(email2, password2)).called(1);
      });
    });

    group('User state validation', () {
      test('should handle user with null optional fields', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final userWithNulls = User(
          id: 'user_nulls',
          email: email,
          name: 'User Name',
          displayName: null, // Null display name
          role: UserRole.user,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          isOnline: null, // Null online status
        );

        when(mockRepository.signIn(email, password))
            .thenAnswer((_) async => userWithNulls);

        // Act
        final result = await usecase.call(email, password);

        // Assert
        expect(result, equals(userWithNulls));
        expect(result!.displayName, isNull);
        expect(result.isOnline, isNull);
        verify(mockRepository.signIn(email, password)).called(1);
      });

      test('should handle user with all roles correctly', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';

        for (final role in UserRole.values) {
          final userWithRole = testUser.copyWith(role: role);
          when(mockRepository.signIn(email, password))
              .thenAnswer((_) async => userWithRole);

          // Act
          final result = await usecase.call(email, password);

          // Assert
          expect(result!.role, equals(role));
          verify(mockRepository.signIn(email, password)).called(1);
        }
      });
    });
  });
}
