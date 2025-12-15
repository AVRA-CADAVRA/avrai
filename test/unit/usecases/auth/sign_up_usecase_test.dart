import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/user.dart';
import 'package:spots/domain/repositories/auth_repository.dart';
import 'package:spots/domain/usecases/auth/sign_up_usecase.dart';

import 'sign_up_usecase_test.mocks.dart';

// Generate mocks
@GenerateMocks([AuthRepository])
void main() {
  group('SignUpUseCase', () {
    late SignUpUseCase usecase;
    late MockAuthRepository mockRepository;
    late User testUser;

    setUp(() {
      mockRepository = MockAuthRepository();
      usecase = SignUpUseCase(mockRepository);
      
      testUser = User(
        id: 'new_user_123',
        email: 'newuser@example.com',
        name: 'New User',
        displayName: 'New Display Name',
        role: UserRole.user,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        isOnline: true,
      );
    });

    group('Successful sign up', () {
      test('should create new user successfully with valid data', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'validPassword123';
        const name = 'New User';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, equals(testUser));
        expect(result!.email, equals(email));
        expect(result.name, equals(name));
        expect(result.role, equals(UserRole.user));
        verify(mockRepository.signUp(email, password, name)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('should create user with different name formats', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final nameFormats = [
          'John',
          'John Doe',
          'John Michael Doe',
          'Dr. John Doe Jr.',
          'María García',
          'Jean-Pierre Dupont',
          "O'Connor",
          '李明',
          'محمد علي',
        ];

        for (final name in nameFormats) {
          final userWithName = testUser.copyWith(
            name: name,
            id: 'user_${name.hashCode}',
          );

          when(mockRepository.signUp(email, password, name))
              .thenAnswer((_) async => userWithName);

          // Act
          final result = await usecase.call(email, password, name);

          // Assert
          expect(result, isNotNull);
          expect(result!.name, equals(name));
          verify(mockRepository.signUp(email, password, name)).called(1);
        }
      });

      test('should create user with different email formats', () async {
        // Arrange
        const password = 'password';
        const name = 'Test User';
        final emailFormats = [
          'simple@example.com',
          'user.name@example.com',
          'user+tag@example.com',
          'user_name@example-domain.com',
          'user123@sub.domain.co.uk',
          'очень.длинный@домен.рф',
        ];

        for (final email in emailFormats) {
          final userWithEmail = testUser.copyWith(
            email: email,
            id: 'user_${email.hashCode}',
          );

          when(mockRepository.signUp(email, password, name))
              .thenAnswer((_) async => userWithEmail);

          // Act
          final result = await usecase.call(email, password, name);

          // Assert
          expect(result, isNotNull);
          expect(result!.email, equals(email));
          verify(mockRepository.signUp(email, password, name)).called(1);
        }
      });

      test('should create user with different password types', () async {
        // Arrange
        const email = 'test@example.com';
        const name = 'Test User';
        final passwords = [
          'short',
          'verylongpasswordwithmanycharactersmakingitextremelylongfortesting',
          'P@ssw0rd!',
          '123456789',
          'password with spaces',
          'пароль123',
          'パスワード456',
          r'!@#$%^&*()_+-=[]{}|;:,.<>?',
        ];

        for (final password in passwords) {
          when(mockRepository.signUp(email, password, name))
              .thenAnswer((_) async => testUser);

          // Act
          final result = await usecase.call(email, password, name);

          // Assert
          expect(result, equals(testUser));
          verify(mockRepository.signUp(email, password, name)).called(1);
        }
      });

      test('should create user with server-generated properties', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final serverGeneratedUser = User(
          id: 'server_generated_id_456',
          email: email,
          name: name,
          displayName: name, // Server sets display name to name
          role: UserRole.user, // Server assigns default role
          createdAt: DateTime(2024, 1, 15, 10, 30, 0),
          updatedAt: DateTime(2024, 1, 15, 10, 30, 0),
          isOnline: true,
        );

        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => serverGeneratedUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, equals(serverGeneratedUser));
        expect(result!.id, equals('server_generated_id_456'));
        expect(result.displayName, equals(name));
        expect(result.role, equals(UserRole.user));
        expect(result.createdAt, equals(result.updatedAt));
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });

    group('Failed sign up scenarios', () {
      test('should return null when email already exists', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'password';
        const name = 'Test User';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should return null when sign up fails', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });

    group('Edge cases and validation', () {
      test('should handle empty name', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const emptyName = '';
        when(mockRepository.signUp(email, password, emptyName))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, password, emptyName);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(email, password, emptyName)).called(1);
      });

      test('should handle empty email', () async {
        // Arrange
        const emptyEmail = '';
        const password = 'password';
        const name = 'Test User';
        when(mockRepository.signUp(emptyEmail, password, name))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(emptyEmail, password, name);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(emptyEmail, password, name)).called(1);
      });

      test('should handle empty password', () async {
        // Arrange
        const email = 'test@example.com';
        const emptyPassword = '';
        const name = 'Test User';
        when(mockRepository.signUp(email, emptyPassword, name))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(email, emptyPassword, name);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(email, emptyPassword, name)).called(1);
      });

      test('should handle all empty fields', () async {
        // Arrange
        const emptyEmail = '';
        const emptyPassword = '';
        const emptyName = '';
        when(mockRepository.signUp(emptyEmail, emptyPassword, emptyName))
            .thenAnswer((_) async => null);

        // Act
        final result = await usecase.call(emptyEmail, emptyPassword, emptyName);

        // Assert
        expect(result, isNull);
        verify(mockRepository.signUp(emptyEmail, emptyPassword, emptyName)).called(1);
      });

      test('should handle whitespace in fields', () async {
        // Arrange
        const email = '  test@example.com  ';
        const password = '  password  ';
        const name = '  Test User  ';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle very long name', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        final longName = 'Very ' * 100 + 'Long Name';
        when(mockRepository.signUp(email, password, longName))
            .thenAnswer((_) async => testUser.copyWith(name: longName));

        // Act
        final result = await usecase.call(email, password, longName);

        // Assert
        expect(result, isNotNull);
        expect(result!.name, equals(longName));
        verify(mockRepository.signUp(email, password, longName)).called(1);
      });

      test('should handle special characters in name', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const specialName = 'Test @#\$%^&*()_+ User';
        when(mockRepository.signUp(email, password, specialName))
            .thenAnswer((_) async => testUser.copyWith(name: specialName));

        // Act
        final result = await usecase.call(email, password, specialName);

        // Assert
        expect(result, isNotNull);
        expect(result!.name, equals(specialName));
        verify(mockRepository.signUp(email, password, specialName)).called(1);
      });

      test('should handle numbers in name', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const numericName = 'User123 Test456';
        when(mockRepository.signUp(email, password, numericName))
            .thenAnswer((_) async => testUser.copyWith(name: numericName));

        // Act
        final result = await usecase.call(email, password, numericName);

        // Assert
        expect(result, isNotNull);
        expect(result!.name, equals(numericName));
        verify(mockRepository.signUp(email, password, numericName)).called(1);
      });

      test('should handle single character fields', () async {
        // Arrange
        const email = 'a@b.c';
        const password = 'p';
        const name = 'N';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => testUser.copyWith(
              email: email,
              name: name,
            ));

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, isNotNull);
        expect(result!.email, equals(email));
        expect(result.name, equals(name));
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });

    group('Error handling', () {
      test('should throw exception when repository throws exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final exception = Exception('Network error during sign up');
        when(mockRepository.signUp(email, password, name))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password, name),
          throwsA(exception),
        );
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle email already exists exception', () async {
        // Arrange
        const email = 'existing@example.com';
        const password = 'password';
        const name = 'Test User';
        final emailExistsError = Exception('Email already exists');
        when(mockRepository.signUp(email, password, name))
            .thenThrow(emailExistsError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password, name),
          throwsA(emailExistsError),
        );
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle password too weak exception', () async {
        // Arrange
        const email = 'test@example.com';
        const weakPassword = '123';
        const name = 'Test User';
        final weakPasswordError = Exception('Password too weak');
        when(mockRepository.signUp(email, weakPassword, name))
            .thenThrow(weakPasswordError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, weakPassword, name),
          throwsA(weakPasswordError),
        );
        verify(mockRepository.signUp(email, weakPassword, name)).called(1);
      });

      test('should handle invalid email format exception', () async {
        // Arrange
        const invalidEmail = 'not-an-email';
        const password = 'password';
        const name = 'Test User';
        final invalidEmailError = Exception('Invalid email format');
        when(mockRepository.signUp(invalidEmail, password, name))
            .thenThrow(invalidEmailError);

        // Act & Assert
        expect(
          () async => await usecase.call(invalidEmail, password, name),
          throwsA(invalidEmailError),
        );
        verify(mockRepository.signUp(invalidEmail, password, name)).called(1);
      });

      test('should handle server error during sign up', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final serverError = Exception('Internal server error');
        when(mockRepository.signUp(email, password, name))
            .thenThrow(serverError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password, name),
          throwsA(serverError),
        );
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle rate limiting exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final rateLimitError = Exception('Too many sign up attempts');
        when(mockRepository.signUp(email, password, name))
            .thenThrow(rateLimitError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password, name),
          throwsA(rateLimitError),
        );
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle validation exception', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final validationError = ArgumentError('Validation failed');
        when(mockRepository.signUp(email, password, name))
            .thenThrow(validationError);

        // Act & Assert
        expect(
          () async => await usecase.call(email, password, name),
          throwsA(validationError),
        );
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });

    group('Business logic validation', () {
      test('should pass parameters exactly as provided to repository', () async {
        // Arrange
        const email = 'EXACT@Example.COM';
        const password = 'ExactPassword123!';
        const name = 'Exact Name';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, equals(testUser));
        final captured = verify(mockRepository.signUp(captureAny, captureAny, captureAny)).captured;
        expect(captured[0], equals(email));
        expect(captured[1], equals(password));
        expect(captured[2], equals(name));
      });

      test('should not modify or validate data before passing to repository', () async {
        // Arrange
        const rawEmail = '  Raw@Email.com  ';
        const rawPassword = '  RawPassword  ';
        const rawName = '  Raw Name  ';
        when(mockRepository.signUp(rawEmail, rawPassword, rawName))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await usecase.call(rawEmail, rawPassword, rawName);

        // Assert
        expect(result, equals(testUser));
        verify(mockRepository.signUp(rawEmail, rawPassword, rawName)).called(1);
        // Verify it wasn't trimmed or modified
        verifyNever(mockRepository.signUp(
          argThat(equals(rawEmail.trim())),
          argThat(equals(rawPassword.trim())),
          argThat(equals(rawName.trim())),
        ));
      });

      test('should handle concurrent sign up attempts', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => testUser);

        // Act
        final futures = List.generate(3, (_) => usecase.call(email, password, name));
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result, equals(testUser));
        }
        verify(mockRepository.signUp(email, password, name)).called(3);
      });

      test('should be stateless between calls', () async {
        // Arrange
        const email1 = 'user1@example.com';
        const password1 = 'password1';
        const name1 = 'User One';
        const email2 = 'user2@example.com';
        const password2 = 'password2';
        const name2 = 'User Two';

        final user1 = testUser.copyWith(id: 'user1', email: email1, name: name1);
        final user2 = testUser.copyWith(id: 'user2', email: email2, name: name2);

        when(mockRepository.signUp(email1, password1, name1))
            .thenAnswer((_) async => user1);
        when(mockRepository.signUp(email2, password2, name2))
            .thenAnswer((_) async => user2);

        // Act
        final result1 = await usecase.call(email1, password1, name1);
        final result2 = await usecase.call(email2, password2, name2);

        // Assert
        expect(result1!.id, equals('user1'));
        expect(result1.name, equals(name1));
        expect(result2!.id, equals('user2'));
        expect(result2.name, equals(name2));
        verify(mockRepository.signUp(email1, password1, name1)).called(1);
        verify(mockRepository.signUp(email2, password2, name2)).called(1);
      });

      test('should preserve user data structure from repository', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const name = 'Test User';
        final complexUser = User(
          id: 'complex_new_user',
          email: email,
          name: name,
          displayName: '$name Display',
          role: UserRole.user,
          createdAt: DateTime(2024, 1, 15, 14, 30, 45),
          updatedAt: DateTime(2024, 1, 15, 14, 30, 45),
          isOnline: false,
        );

        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => complexUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result, equals(complexUser));
        expect(result!.id, equals('complex_new_user'));
        expect(result.email, equals(email));
        expect(result.name, equals(name));
        expect(result.displayName, equals('$name Display'));
        expect(result.role, equals(UserRole.user));
        expect(result.createdAt, equals(DateTime(2024, 1, 15, 14, 30, 45)));
        expect(result.updatedAt, equals(DateTime(2024, 1, 15, 14, 30, 45)));
        expect(result.isOnline, isFalse);
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle repository returning user with different role', () async {
        // Arrange
        const email = 'moderator@example.com';
        const password = 'password';
        const name = 'Moderator User';
        final moderatorUser = testUser.copyWith(
          role: UserRole.moderator,
          email: email,
          name: name,
        );

        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => moderatorUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result!.role, equals(UserRole.moderator));
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });

    group('New user defaults', () {
      test('should handle user created with default role', () async {
        // Arrange
        const email = 'newuser@example.com';
        const password = 'password';
        const name = 'New User';
        final defaultUser = testUser.copyWith(
          role: UserRole.user, // Default role
          isOnline: true, // Default online status
        );

        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => defaultUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result!.role, equals(UserRole.user));
        expect(result.isOnline, isTrue);
        verify(mockRepository.signUp(email, password, name)).called(1);
      });

      test('should handle user created with server timestamps', () async {
        // Arrange
        const email = 'timestamped@example.com';
        const password = 'password';
        const name = 'Timestamped User';
        final now = DateTime.now();
        final timestampedUser = testUser.copyWith(
          createdAt: now,
          updatedAt: now,
        );

        when(mockRepository.signUp(email, password, name))
            .thenAnswer((_) async => timestampedUser);

        // Act
        final result = await usecase.call(email, password, name);

        // Assert
        expect(result!.createdAt, equals(now));
        expect(result.updatedAt, equals(now));
        expect(result.createdAt, equals(result.updatedAt));
        verify(mockRepository.signUp(email, password, name)).called(1);
      });
    });
  });
}
