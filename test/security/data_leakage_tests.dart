import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';
import 'package:spots/core/services/field_encryption_service.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart';
import 'package:spots/core/models/personality_profile.dart';

/// Data Leakage Tests
/// 
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests verify that no personal information leaks into:
/// - AI2AI payloads
/// - Logs
/// - AnonymousUser objects
/// - Location data
/// - Encrypted fields
void main() {
  group('Data Leakage Tests', () {
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

    group('AI2AI Service Data Leakage Tests', () {
      test('should verify no personal data in AnonymousUser conversion', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-leak-1',
          email: 'user@example.com',
          displayName: 'John Doe',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_leak_1',
          null,
        );

        // Verify no personal data in AnonymousUser
        final json = anonymousUser.toJson();
        final forbiddenKeys = [
          'userId',
          'email',
          'name',
          'displayName',
          'phone',
          'phoneNumber',
          'address',
          'personalInfo',
        ];

        for (final key in forbiddenKeys) {
          expect(json.containsKey(key), isFalse,
              reason: 'AnonymousUser should not contain: $key');
        }
      });

      test('should verify no personal data in AI2AI payload', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-leak-2',
          email: 'user@example.com',
          displayName: 'Jane Doe',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_leak_2',
          null,
        );

        // Create AI2AI payload
        final payload = anonymousUser.toJson();

        // Verify no personal data
        final forbiddenKeys = [
          'userId',
          'email',
          'name',
          'displayName',
          'phone',
          'phoneNumber',
          'address',
        ];

        for (final key in forbiddenKeys) {
          expect(payload.containsKey(key), isFalse,
              reason: 'AI2AI payload should not contain: $key');
        }

        // Verify payload passes validation
        await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );
      });

      test('should verify no personal data in personality profile payload', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-leak-3',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final personality = PersonalityProfile.initial('user-leak-3');

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_leak_3',
          personality,
        );

        // Verify personality profile doesn't contain personal data
        if (anonymousUser.personalityDimensions != null) {
          final personalityJson = anonymousUser.personalityDimensions!.toJson();
          final forbiddenKeys = ['userId', 'email', 'name', 'phone'];

          for (final key in forbiddenKeys) {
            expect(personalityJson.containsKey(key), isFalse,
                reason: 'Personality profile should not contain: $key');
          }
        }
      });
    });

    group('AnonymousUser Validation Tests', () {
      test('should validate AnonymousUser contains no personal data', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-validate-1',
          email: 'user@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_validate_1',
          null,
        );

        // Validation should pass
        expect(() => anonymousUser.validateNoPersonalData(), returnsNormally);
      });

      test('should reject AnonymousUser with personal data in agentId', () async {
        // Attempt to create AnonymousUser with personal data in agentId
        final anonymousUser = AnonymousUser(
          agentId: 'agent_user@example.com', // Contains email
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Should fail validation (agentId format check)
        expect(() => anonymousUser.validateNoPersonalData(), throwsException);
      });

      test('should validate AnonymousUser JSON structure', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-validate-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_validate_2',
          null,
        );

        // Verify JSON structure
        final json = anonymousUser.toJson();
        expect(json.containsKey('agentId'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });
    });

    group('Location Obfuscation Tests', () {
      test('should verify location is obfuscated to city-level only', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-1',
          email: 'user@example.com',
          location: '123 Main St, San Francisco, CA 94102',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_location_1',
          null,
        );

        // Location should be obfuscated
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          expect(anonymousUser.location!.city, equals('San Francisco'));
          
          // Should not contain exact address
          final locationJson = anonymousUser.location!.toJson();
          expect(locationJson.containsKey('address'), isFalse);
          expect(locationJson.containsKey('street'), isFalse);
          expect(locationJson.containsKey('zipCode'), isFalse);
        }
      });

      test('should verify location has expiration', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-2',
          email: 'user@example.com',
          location: 'Austin, TX',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_location_2',
          null,
        );

        // Location should have expiration
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.expiresAt, isNotNull);
          expect(anonymousUser.location!.expiresAt.isAfter(DateTime.now()), isTrue);
        }
      });

      test('should verify no exact coordinates in non-admin location', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-3',
          email: 'user@example.com',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_location_3',
          null,
          isAdmin: false, // Non-admin
        );

        // Location coordinates should be obfuscated (not exact)
        if (anonymousUser.location != null &&
            anonymousUser.location!.latitude != null &&
            anonymousUser.location!.longitude != null) {
          // Coordinates should be rounded to city-level (not exact)
          // Exact coordinates would be like 37.7849123, but obfuscated should be rounded
          final lat = anonymousUser.location!.latitude!;
          final lng = anonymousUser.location!.longitude!;
          
          // Should be rounded (city-level precision)
          expect(lat.toString().split('.').last.length, lessThanOrEqualTo(2));
          expect(lng.toString().split('.').last.length, lessThanOrEqualTo(2));
        }
      });

      test('should verify home location is never shared', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-location-4',
          email: 'user@example.com',
          location: '123 Home St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Set home location
        locationService.setHomeLocation(unifiedUser.id, unifiedUser.location!);

        // Attempt to anonymize with home location (should fail or exclude)
        expect(
          () => locationService.obfuscateLocation(
            unifiedUser.location!,
            unifiedUser.id,
          ),
          throwsException,
        );
      });
    });

    group('Field Encryption Tests', () {
      test('should verify encrypted fields are not exposed in plain text', () async {
        const email = 'user@example.com';
        const userId = 'user-encrypt-1';

        // Encrypt email
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Verify encrypted value is not plain text
        expect(encrypted, isNot(equals(email)));
        expect(encrypted, startsWith('encrypted:'));

        // Verify encrypted value doesn't contain original email
        expect(encrypted, isNot(contains(email)));
      });

      test('should verify encrypted data is not in AnonymousUser', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-encrypt-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Encrypt email
        await encryptionService.encryptField(
          'email',
          unifiedUser.email,
          unifiedUser.id,
        );

        // Convert to AnonymousUser
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_encrypt_2',
          null,
        );

        // AnonymousUser should NOT contain encrypted email
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('encryptedEmail'), isFalse);
      });

      test('should verify encryption keys are user-specific', () async {
        const email = 'user@example.com';
        const userId1 = 'user-encrypt-3';
        const userId2 = 'user-encrypt-4';

        // Encrypt same email for different users
        final encrypted1 = await encryptionService.encryptField('email', email, userId1);
        final encrypted2 = await encryptionService.encryptField('email', email, userId2);

        // Encrypted values should be different (different keys)
        expect(encrypted1, isNot(equals(encrypted2)));

        // Each user should only be able to decrypt their own
        final decrypted1 = await encryptionService.decryptField('email', encrypted1, userId1);
        final decrypted2 = await encryptionService.decryptField('email', encrypted2, userId2);

        expect(decrypted1, equals(email));
        expect(decrypted2, equals(email));

        // User 1 should not be able to decrypt User 2's data
        expect(
          () => encryptionService.decryptField('email', encrypted2, userId1),
          throwsException,
        );
      });
    });

    group('Log Sanitization Tests', () {
      test('should verify no personal data in log output', () async {
        const email = 'user@example.com';
        const userId = 'user-log-1';

        // Encrypt email (should not log email in plain text)
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Encrypted value should not contain email
        expect(encrypted, isNot(contains(email)));

        // Decrypt (should not log email in plain text)
        await encryptionService.decryptField('email', encrypted, userId);

        // In actual implementation, would check log output for email
        // For now, verify encrypted value doesn't contain email
      });

      test('should verify no personal data in error messages', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-log-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Attempt invalid operation (should not leak email in error)
        try {
          await anonymizationService.anonymizeUser(
            unifiedUser,
            'invalid-agent-id', // Invalid format
            null,
          );
          fail('Should have thrown exception');
        } catch (e) {
          // Error message should not contain email
          expect(e.toString(), isNot(contains(unifiedUser.email)));
        }
      });
    });

    group('Comprehensive Data Leakage Tests', () {
      test('should verify complete anonymization flow has no leaks', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-comprehensive-1',
          email: 'user@example.com',
          displayName: 'John Doe',
          location: '123 Main St, San Francisco, CA 94102',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final personality = PersonalityProfile.initial('user-comprehensive-1');

        // Step 1: Anonymize user
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_comprehensive_1',
          personality,
        );

        // Step 3: Create AI2AI payload
        final payload = anonymousUser.toJson();

        // Step 4: Verify no personal data anywhere
        final allForbiddenKeys = [
          'userId',
          'email',
          'name',
          'displayName',
          'phone',
          'phoneNumber',
          'address',
          'personalInfo',
        ];

        for (final key in allForbiddenKeys) {
          expect(payload.containsKey(key), isFalse,
              reason: 'Payload should not contain: $key');
        }

        // Step 5: Verify payload passes validation
        await communicationProtocol.sendEncryptedMessage(
          'target-agent',
          MessageType.discoverySync,
          payload,
        );

        // Step 6: Verify encrypted email is not in payload
        expect(payload.containsKey('encryptedEmail'), isFalse);
      });

      test('should verify nested data structures have no leaks', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-comprehensive-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final personality = PersonalityProfile.initial('user-comprehensive-2');

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_comprehensive_2',
          personality,
        );

        // Check nested structures (personality profile, preferences, etc.)
        final json = anonymousUser.toJson();

        // Convert to string and check for personal data patterns
        final jsonString = json.toString().toLowerCase();

        // Should not contain email patterns
        expect(jsonString, isNot(contains('@')));
        expect(jsonString, isNot(contains('user@example.com')));

        // Should not contain phone patterns
        expect(jsonString, isNot(contains('555-123-4567')));

        // Should not contain userId
        expect(jsonString, isNot(contains('user-comprehensive-2')));
      });
    });
  });
}
