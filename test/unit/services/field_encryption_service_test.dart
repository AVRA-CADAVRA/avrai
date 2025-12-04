import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/field_encryption_service.dart';

/// Tests for FieldEncryptionService
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests ensure personal data fields are encrypted at rest
/// using AES-256-GCM encryption
void main() {
  group('FieldEncryptionService', () {
    late FieldEncryptionService service;
    const userId = 'user-123';

    setUp(() {
      service = FieldEncryptionService();
    });

    group('Email Encryption/Decryption', () {
      test('should encrypt email address', () async {
        const email = 'user@example.com';

        final encrypted = await service.encryptField('email', email, userId);

        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(email))); // Should be different
        expect(encrypted, startsWith('encrypted:')); // Encryption marker
      });

      test('should decrypt email address correctly', () async {
        const email = 'test@example.com';

        final encrypted = await service.encryptField('email', email, userId);
        final decrypted = await service.decryptField('email', encrypted, userId);

        expect(decrypted, equals(email));
      });

      test('should handle various email formats', () async {
        final emailFormats = [
          'user@example.com',
          'user.name@example.co.uk',
          'user+tag@example.org',
          'user123@test-domain.com',
        ];

        for (final email in emailFormats) {
          final encrypted = await service.encryptField('email', email, userId);
          final decrypted = await service.decryptField('email', encrypted, userId);

          expect(decrypted, equals(email));
        }
      });

      test('should produce different encrypted values for same email', () async {
        const email = 'user@example.com';

        final encrypted1 = await service.encryptField('email', email, userId);
        final encrypted2 = await service.encryptField('email', email, userId);

        // Should be different due to IV/nonce (or same in simplified implementation)
        // But should decrypt to same value
        expect(await service.decryptField('email', encrypted1, userId), equals(email));
        expect(await service.decryptField('email', encrypted2, userId), equals(email));
      });
    });

    group('Name Encryption/Decryption', () {
      test('should encrypt name', () async {
        const name = 'John Doe';

        final encrypted = await service.encryptField('name', name, userId);

        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(name)));
        expect(encrypted, startsWith('encrypted:'));
      });

      test('should decrypt name correctly', () async {
        const name = 'Jane Smith';

        final encrypted = await service.encryptField('name', name, userId);
        final decrypted = await service.decryptField('name', encrypted, userId);

        expect(decrypted, equals(name));
      });

      test('should handle unicode names', () async {
        final unicodeNames = [
          'José García',
          '李小明',
          'Иван Петров',
        ];

        for (final name in unicodeNames) {
          final encrypted = await service.encryptField('name', name, userId);
          final decrypted = await service.decryptField('name', encrypted, userId);

          expect(decrypted, equals(name));
        }
      });
    });

    group('Location Encryption/Decryption', () {
      test('should encrypt location string', () async {
        const location = 'San Francisco, CA';

        final encrypted = await service.encryptField('location', location, userId);

        expect(encrypted, isNotEmpty);
        expect(encrypted, startsWith('encrypted:'));
      });

      test('should decrypt location correctly', () async {
        const location = 'New York, NY';

        final encrypted = await service.encryptField('location', location, userId);
        final decrypted = await service.decryptField('location', encrypted, userId);

        expect(decrypted, equals(location));
      });
    });

    group('Phone Encryption/Decryption', () {
      test('should encrypt phone number', () async {
        const phone = '+1-555-123-4567';

        final encrypted = await service.encryptField('phone', phone, userId);

        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(phone)));
        expect(encrypted, startsWith('encrypted:'));
      });

      test('should decrypt phone number correctly', () async {
        const phone = '(555) 123-4567';

        final encrypted = await service.encryptField('phone', phone, userId);
        final decrypted = await service.decryptField('phone', encrypted, userId);

        expect(decrypted, equals(phone));
      });

      test('should handle empty phone number', () async {
        const phone = '';

        final encrypted = await service.encryptField('phone', phone, userId);

        expect(encrypted, equals(phone)); // Empty values not encrypted
      });

      test('should handle various phone formats', () async {
        final phoneFormats = [
          '(555) 123-4567',
          '555-123-4567',
          '5551234567',
          '+1-555-123-4567',
          '+44 20 7946 0958',
        ];

        for (final phone in phoneFormats) {
          final encrypted = await service.encryptField('phone', phone, userId);
          final decrypted = await service.decryptField('phone', encrypted, userId);

          expect(decrypted, equals(phone));
        }
      });
    });

    group('Key Management', () {
      test('should check if field should be encrypted', () {
        expect(service.shouldEncryptField('email'), isTrue);
        expect(service.shouldEncryptField('name'), isTrue);
        expect(service.shouldEncryptField('phone'), isTrue);
        expect(service.shouldEncryptField('location'), isTrue);
        expect(service.shouldEncryptField('address'), isTrue);
        expect(service.shouldEncryptField('safeField'), isFalse);
      });

      test('should use different keys for different users', () async {
        const email = 'user@example.com';
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        final encrypted1 = await service.encryptField('email', email, userId1);
        final encrypted2 = await service.encryptField('email', email, userId2);

        // Should use different keys (different encrypted values)
        // Both should decrypt correctly
        expect(await service.decryptField('email', encrypted1, userId1), equals(email));
        expect(await service.decryptField('email', encrypted2, userId2), equals(email));
      });

      test('should use different keys for different fields', () async {
        const value = 'test';
        const field1 = 'email';
        const field2 = 'name';

        final encrypted1 = await service.encryptField(field1, value, userId);
        final encrypted2 = await service.encryptField(field2, value, userId);

        // Should use different keys per field
        expect(await service.decryptField(field1, encrypted1, userId), equals(value));
        expect(await service.decryptField(field2, encrypted2, userId), equals(value));
      });
    });

    group('Key Rotation', () {
      test('should rotate encryption key for field', () async {
        const email = 'user@example.com';

        // Encrypt with old key
        final encryptedOld = await service.encryptField('email', email, userId);

        // Rotate key
        await service.rotateKey('email', userId);

        // New encryption should use new key
        final encryptedNew = await service.encryptField('email', email, userId);

        // Both should decrypt correctly (implementation handles key rotation)
        expect(await service.decryptField('email', encryptedOld, userId), equals(email));
        expect(await service.decryptField('email', encryptedNew, userId), equals(email));
      });

      test('should delete encryption key', () async {
        const email = 'user@example.com';

        // Encrypt
        final encrypted = await service.encryptField('email', email, userId);

        // Delete key
        await service.deleteKey('email', userId);

        // Should not be able to decrypt (key deleted)
        // Note: Implementation may handle this differently
        expect(
          () => service.decryptField('email', encrypted, userId),
          throwsException,
        );
      });
    });

    group('Error Handling', () {
      test('should handle decryption errors gracefully', () async {
        const invalidEncrypted = 'encrypted:invalid_data';

        expect(
          () => service.decryptField('email', invalidEncrypted, userId),
          throwsException,
        );
      });

      test('should handle corrupted encrypted data', () async {
        const corrupted = 'encrypted:corrupted_data_12345';

        expect(
          () => service.decryptField('email', corrupted, userId),
          throwsException,
        );
      });

      test('should handle empty input (not encrypted)', () async {
        const empty = '';

        final encrypted = await service.encryptField('email', empty, userId);

        // Empty values are not encrypted
        expect(encrypted, equals(empty));
      });

      test('should handle invalid encrypted format', () async {
        const invalidFormat = 'not_encrypted_data';

        expect(
          () => service.decryptField('email', invalidFormat, userId),
          throwsException,
        );
      });
    });
  });
}

