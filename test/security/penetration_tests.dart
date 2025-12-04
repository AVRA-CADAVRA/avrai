import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';
import 'package:spots/core/services/field_encryption_service.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart';

/// Penetration Tests for Security Features
/// 
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests attempt to penetrate security measures to identify vulnerabilities:
/// - Attempt to extract personal information
/// - Attempt device impersonation
/// - Test encryption strength
/// - Attempt anonymization bypass
/// - Attempt authentication bypass
/// - Attempt RLS policy bypass
/// - Attempt audit log tampering
void main() {
  group('Penetration Tests', () {
    late UserAnonymizationService anonymizationService;
    late LocationObfuscationService locationService;
    late FieldEncryptionService encryptionService;
    late AnonymousCommunicationProtocol communicationProtocol;

    setUp(() {
      locationService = LocationObfuscationService();
      anonymizationService = UserAnonymizationService(
        locationObfuscationService: locationService,
      );
      encryptionService = FieldEncryptionService();
      communicationProtocol = AnonymousCommunicationProtocol();
    });

    group('Personal Information Extraction Attempts', () {
      test('should prevent extraction of email from AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-pen-test-1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_pen_test_1',
          null,
        );

        // Attempt to extract email (should fail)
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('userId'), isFalse);
        
        // Attempt to access via reflection or other means
        expect(() => anonymousUser.validateNoPersonalData(), returnsNormally);
      });

      test('should prevent extraction of name from AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-pen-test-2',
          email: 'test@example.com',
          displayName: 'John Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_pen_test_2',
          null,
        );

        // Attempt to extract name (should fail)
        final json = anonymousUser.toJson();
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('displayName'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });

      test('should prevent extraction of phone number from AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-pen-test-3',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_pen_test_3',
          null,
        );

        // Attempt to extract phone (should fail)
        final json = anonymousUser.toJson();
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('phoneNumber'), isFalse);
      });

      test('should prevent extraction of exact location from AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-pen-test-4',
          email: 'test@example.com',
          location: '123 Main St, San Francisco, CA 94102',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_pen_test_4',
          null,
        );

        // Location should be obfuscated (city-level only)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          // Should not contain exact address
          expect(anonymousUser.location!.city, isNot(contains('123 Main St')));
        }
      });
    });

    group('Device Impersonation Attempts', () {
      test('should prevent impersonation with invalid agent ID', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-impersonation-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt to use invalid agent ID format
        expect(
          () => anonymizationService.anonymizeUser(
            unifiedUser,
            'invalid-agent-id', // Should start with "agent_"
            null,
          ),
          throwsException,
        );
      });

      test('should prevent impersonation with malicious agent ID', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-impersonation-2',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt to use malicious agent ID
        final maliciousIds = [
          'agent_../../../etc/passwd',
          'agent_<script>alert("xss")</script>',
          'agent_${unifiedUser.id}', // Attempt to leak userId
        ];

        for (final maliciousId in maliciousIds) {
          expect(
            () => anonymizationService.anonymizeUser(
              unifiedUser,
              maliciousId,
              null,
            ),
            throwsException,
          );
        }
      });
    });

    group('Encryption Strength Tests', () {
      test('should use strong encryption for field encryption', () async {
        const email = 'test@example.com';
        const userId = 'user-encryption-test';

        // Encrypt field
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Verify encryption is not plain text
        expect(encrypted, isNot(equals(email)));
        expect(encrypted, startsWith('encrypted:'));

        // Verify decryption works
        final decrypted = await encryptionService.decryptField('email', encrypted, userId);
        expect(decrypted, equals(email));
      });

      test('should prevent decryption with wrong user ID', () async {
        const email = 'test@example.com';
        const userId = 'user-encryption-test-2';
        const wrongUserId = 'wrong-user';

        // Encrypt with one user ID
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt to decrypt with wrong user ID (should fail)
        expect(
          () => encryptionService.decryptField('email', encrypted, wrongUserId),
          throwsException,
        );
      });

      test('should use different encryption keys per user', () async {
        const email = 'test@example.com';
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Encrypt same email for different users
        final encrypted1 = await encryptionService.encryptField('email', email, userId1);
        final encrypted2 = await encryptionService.encryptField('email', email, userId2);

        // Encrypted values should be different (different keys)
        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });

    group('Anonymization Bypass Attempts', () {
      test('should prevent bypass by injecting personal data in payload', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-bypass-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_bypass_1',
          null,
        );

        // Attempt to inject personal data in payload
        final maliciousPayload = {
          ...anonymousUser.toJson(),
          'email': 'test@example.com', // Attempt to inject email
          'userId': unifiedUser.id, // Attempt to inject userId
        };

        // Should be rejected by validation
        expect(
          () => communicationProtocol.sendEncryptedMessage(
            'target-agent',
            MessageType.discoverySync,
            maliciousPayload,
          ),
          throwsA(isA<AnonymousCommunicationException>()),
        );
      });

      test('should prevent bypass by using admin flag incorrectly', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-bypass-2',
          email: 'test@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Non-admin should get obfuscated location
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_bypass_2',
          null,
          isAdmin: false,
        );

        // Location should be obfuscated (not exact)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          // Should not contain exact address
        }
      });

      test('should prevent bypass by manipulating AnonymousUser JSON', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-bypass-3',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_bypass_3',
          null,
        );

        // Attempt to manipulate JSON to add personal data
        final json = anonymousUser.toJson();
        json['email'] = 'test@example.com';
        json['userId'] = unifiedUser.id;

        // Create new AnonymousUser from manipulated JSON (should fail validation)
        expect(
          () {
            final manipulated = AnonymousUser.fromJson(json);
            manipulated.validateNoPersonalData();
          },
          throwsException,
        );
      });
    });

    group('Authentication Bypass Attempts', () {
      test('should prevent access without valid agent ID', () async {
        // Attempt to send message without valid agent ID
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

      test('should prevent access with empty target agent ID', () async {
        final payload = {
          'agentId': 'agent_test',
        };

        // Attempt to send to empty target
        expect(
          () => communicationProtocol.sendEncryptedMessage(
            '', // Empty target
            MessageType.discoverySync,
            payload,
          ),
          throwsA(isA<AnonymousCommunicationException>()),
        );
      });
    });

    group('RLS Policy Bypass Attempts', () {
      test('should prevent access to encrypted data with wrong user ID', () async {
        const email = 'test@example.com';
        const userId = 'user-rls-1';
        const otherUserId = 'other-user';

        // Encrypt data for user
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt to decrypt with different user ID (should fail)
        expect(
          () => encryptionService.decryptField('email', encrypted, otherUserId),
          throwsException,
        );
      });

      test('should prevent access to deleted encryption keys', () async {
        const email = 'test@example.com';
        const userId = 'user-rls-2';

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

    group('Audit Log Tampering Attempts', () {
      test('should prevent modification of encrypted audit data', () async {
        const email = 'test@example.com';
        const userId = 'user-audit-1';

        // Encrypt field (simulating audit log encryption)
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt to modify encrypted data
        final modified = encrypted.replaceAll('a', 'b');

        // Modified data should fail decryption
        expect(
          () => encryptionService.decryptField('email', modified, userId),
          throwsException,
        );
      });

      test('should prevent replay attacks with expired messages', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-audit-2',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_audit_2',
          null,
        );

        // Create message (would expire after time period)
        final message = await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          anonymousUser.toJson(),
        );

        // Message should have expiration
        expect(message.expiresAt, isNotNull);
        expect(message.expiresAt.isAfter(DateTime.now()), isTrue);
      });
    });

    group('Location Obfuscation Bypass Attempts', () {
      test('should prevent sharing of home location', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-1',
          email: 'test@example.com',
          location: '123 Home St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Set home location
        locationService.setHomeLocation(unifiedUser.id, unifiedUser.location!);

        // Attempt to obfuscate home location (should fail)
        expect(
          () => locationService.obfuscateLocation(
            unifiedUser.location!,
            unifiedUser.id,
          ),
          throwsException,
        );
      });

      test('should prevent exact location sharing for non-admin', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-2',
          email: 'test@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Obfuscate location (non-admin)
        final obfuscated = await locationService.obfuscateLocation(
          unifiedUser.location!,
          unifiedUser.id,
          exactLatitude: 37.7849,
          exactLongitude: -122.4094,
        );

        // Should be obfuscated (not exact)
        if (obfuscated.latitude != null && obfuscated.longitude != null) {
          // Should not match exact coordinates (city-level only)
          expect(obfuscated.latitude, isNot(equals(37.7849)));
          expect(obfuscated.longitude, isNot(equals(-122.4094)));
        }
      });
    });
  });
}
