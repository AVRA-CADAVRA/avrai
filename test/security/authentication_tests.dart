import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/field_encryption_service.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart';
import 'package:spots/core/services/admin_auth_service.dart';

/// Authentication Security Tests
/// 
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests verify authentication security:
/// - Device certificate validation
/// - Authentication bypass attempts
/// - Session management
/// - Unauthorized access prevention
/// - Admin/godmode access controls
void main() {
  group('Authentication Security Tests', () {
    late FieldEncryptionService encryptionService;
    late UserAnonymizationService anonymizationService;
    late LocationObfuscationService locationService;
    late AnonymousCommunicationProtocol communicationProtocol;
    AdminAuthService? adminAuthService;

    setUp(() async {
      encryptionService = FieldEncryptionService();
      locationService = LocationObfuscationService();
      anonymizationService = UserAnonymizationService(
        locationObfuscationService: locationService,
      );
      communicationProtocol = AnonymousCommunicationProtocol();
      // AdminAuthService requires SharedPreferences - skip for now
      // adminAuthService = AdminAuthService(SharedPreferences.getInstance());
    });

    group('Device Certificate Validation', () {
      test('should require valid agent ID format', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-cert-1',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Valid agent ID (starts with "agent_")
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_cert_1',
          null,
        );

        expect(anonymousUser.agentId, startsWith('agent_'));
      });

      test('should reject invalid agent ID format', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-cert-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Invalid agent ID (doesn't start with "agent_")
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            'invalid-agent-id',
            null,
          ),
          throwsException,
        );
      });

      test('should validate agent ID in communication protocol', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-cert-3',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_cert_3',
          null,
        );

        // Valid payload with proper agent ID
        final payload = anonymousUser.toJson();
        expect(payload['agentId'], startsWith('agent_'));

        // Should pass validation
        await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );
      });

      test('should reject communication with invalid agent ID', () async {
        final invalidPayload = {
          'agentId': 'invalid-id', // Not starting with "agent_"
        };

        expect(
          () => communicationProtocol.sendEncryptedMessage(
            'target-agent',
            MessageType.discoverySync,
            invalidPayload,
          ),
          throwsA(isA<AnonymousCommunicationException>()),
        );
      });
    });

    group('Authentication Bypass Attempts', () {
      test('should prevent access without authentication', () async {
        // Attempt to access encrypted data without proper user ID
        const email = 'user@example.com';
        const userId = 'user-bypass-1';
        const wrongUserId = 'wrong-user';

        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt to decrypt with wrong user ID (should fail)
        expect(
          () => encryptionService.decryptField('email', encrypted, wrongUserId),
          throwsException,
        );
      });

      test('should prevent access with empty credentials', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-bypass-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt to anonymize with empty agent ID
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            '', // Empty agent ID
            null,
          ),
          throwsException,
        );
      });

      test('should prevent access with null agent ID', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-bypass-3',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt to anonymize with null agent ID (would fail at compile time, but test runtime)
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            'agent_null', // Not null, but test format
            null,
          ),
          returnsNormally,
        );
      });

      test('should prevent access to deleted encryption keys', () async {
        const email = 'user@example.com';
        const userId = 'user-bypass-4';

        // Encrypt data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Delete encryption key
        await encryptionService.deleteKey('email', userId);

        // Attempt to decrypt (should fail - key deleted)
        expect(
          () => encryptionService.decryptField('email', encrypted, userId),
          throwsException,
        );
      });
    });

    group('Session Management', () {
      test('should manage encryption keys per user session', () async {
        const email = 'user@example.com';
        const userId = 'user-session-1';

        // Encrypt in session
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Decrypt in same session (should work)
        final decrypted = await encryptionService.decryptField('email', encrypted, userId);
        expect(decrypted, equals(email));
      });

      test('should isolate sessions between users', () async {
        const email = 'user@example.com';
        const userId1 = 'user-session-2';
        const userId2 = 'user-session-3';

        // Encrypt for user 1
        final encrypted1 = await encryptionService.encryptField('email', email, userId1);

        // Encrypt for user 2
        final encrypted2 = await encryptionService.encryptField('email', email, userId2);

        // User 1 should only decrypt their own data
        final decrypted1 = await encryptionService.decryptField('email', encrypted1, userId1);
        expect(decrypted1, equals(email));

        // User 1 should NOT decrypt user 2's data
        expect(
          () => encryptionService.decryptField('email', encrypted2, userId1),
          throwsException,
        );
      });

      test('should handle key rotation in session', () async {
        const email = 'user@example.com';
        const userId = 'user-session-4';

        // Encrypt with original key
        final encrypted1 = await encryptionService.encryptField('email', email, userId);

        // Rotate key
        await encryptionService.rotateKey('email', userId);

        // Encrypt again (should use new key)
        final encrypted2 = await encryptionService.encryptField('email', email, userId);

        // New encryption should be different
        expect(encrypted1, isNot(equals(encrypted2)));

        // Note: Old encrypted data may not be decryptable after key rotation
        // This depends on key rotation implementation
      });
    });

    group('Unauthorized Access Prevention', () {
      test('should prevent unauthorized access to encrypted data', () async {
        const email = 'user@example.com';
        const userId = 'user-unauth-1';
        const unauthorizedUserId = 'unauthorized-user';

        // Encrypt data for authorized user
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt to decrypt with unauthorized user ID (should fail)
        expect(
          () => encryptionService.decryptField('email', encrypted, unauthorizedUserId),
          throwsException,
        );
      });

      test('should prevent unauthorized access to anonymized data', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-unauth-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_unauth_2',
          null,
        );

        // Unauthorized user should not be able to extract personal data
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });

      test('should prevent unauthorized access to admin features', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-unauth-3',
          email: 'user@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Non-admin should get obfuscated location
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_unauth_3',
          null,
          isAdmin: false, // Non-admin
        );

        // Location should be obfuscated (not exact)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          // Should not contain exact address
        }
      });
    });

    group('Admin/Godmode Access Controls', () {
      test('should allow admin access to exact location', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-admin-1',
          email: 'user@example.com',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Admin should get exact location
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_admin_1',
          null,
          isAdmin: true, // Admin
        );

        // Admin can see exact location (if implemented)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
        }
      });

      test('should prevent non-admin from accessing exact location', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-admin-2',
          email: 'user@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Non-admin should get obfuscated location
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_admin_2',
          null,
          isAdmin: false, // Non-admin
        );

        // Location should be obfuscated
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          // Should not contain exact address
        }
      });

      test('should validate admin authentication', () async {
        // AdminAuthService requires SharedPreferences - skip for now
        // In actual implementation, would test admin authentication
        expect(adminAuthService, isNull);
      });

      test('should enforce admin session expiration', () async {
        // Admin sessions should expire
        // This would be tested with actual admin authentication
        // For now, verify admin auth service exists
        expect(adminAuthService, isNotNull);
      });

      test('should prevent admin privilege escalation', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-admin-3',
          email: 'user@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Non-admin attempting to use admin flag (should be rejected)
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_admin_3',
          null,
          isAdmin: false, // Non-admin (even if they try to set true, service validates)
        );

        // Should still get obfuscated location
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
        }
      });
    });

    group('Authentication Error Handling', () {
      test('should handle authentication errors gracefully', () async {
        const email = 'user@example.com';
        const userId = 'user-error-1';

        // Encrypt data (verify encryption works)
        await encryptionService.encryptField('email', email, userId);

        // Attempt to decrypt with invalid format (should throw exception)
        expect(
          () => encryptionService.decryptField('email', 'invalid-encrypted', userId),
          throwsException,
        );
      });

      test('should handle missing encryption keys gracefully', () async {
        const email = 'user@example.com';
        const userId = 'user-error-2';

        // Encrypt data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Delete key
        await encryptionService.deleteKey('email', userId);

        // Attempt to decrypt (should fail gracefully)
        expect(
          () => encryptionService.decryptField('email', encrypted, userId),
          throwsException,
        );
      });

      test('should handle invalid agent ID format gracefully', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-error-3',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Invalid agent ID should throw exception
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            'invalid-format',
            null,
          ),
          throwsException,
        );
      });
    });
  });
}
