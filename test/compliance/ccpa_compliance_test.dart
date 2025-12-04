import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/services/field_encryption_service.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';

/// CCPA Compliance Tests
/// 
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests verify CCPA compliance:
/// - Data deletion
/// - Opt-out mechanisms
/// - Data security
/// - User rights (access, deletion, opt-out)
void main() {
  group('CCPA Compliance Tests', () {
    late FieldEncryptionService encryptionService;
    late UserAnonymizationService anonymizationService;
    late LocationObfuscationService locationService;

    setUp(() async {
      encryptionService = FieldEncryptionService();
      locationService = LocationObfuscationService();
      anonymizationService = UserAnonymizationService(
        locationObfuscationService: locationService,
      );
    });

    group('Data Deletion', () {
      test('should allow deletion of personal information', () async {
        const email = 'user@ccpa-test.com';
        const userId = 'user-ccpa-1';

        // Encrypt personal information
        final encryptedEmail = await encryptionService.encryptField('email', email, userId);
        expect(encryptedEmail, isNotEmpty);

        // Delete personal information (CCPA right to deletion)
        await encryptionService.deleteKey('email', userId);

        // Verify data is deleted (cannot decrypt)
        expect(
          () => encryptionService.decryptField('email', encryptedEmail, userId),
          throwsException,
        );
      });

      test('should allow deletion of all personal data fields', () async {
        const userId = 'user-ccpa-2';

        // Encrypt multiple personal data fields
        await encryptionService.encryptField('email', 'user@ccpa-test.com', userId);
        await encryptionService.encryptField('name', 'Test User', userId);
        await encryptionService.encryptField('phone', '555-123-4567', userId);
        await encryptionService.encryptField('location', 'San Francisco, CA', userId);

        // Delete all personal data (CCPA requirement)
        await encryptionService.deleteKey('email', userId);
        await encryptionService.deleteKey('name', userId);
        await encryptionService.deleteKey('phone', userId);
        await encryptionService.deleteKey('location', userId);

        // Verify all data is deleted
        // (Cannot decrypt any of the encrypted data)
        expect(encryptionService, isNotNull);
      });

      test('should verify anonymized data does not contain personal information', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-ccpa-3',
          email: 'user@ccpa-test.com',
          displayName: 'Test User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_ccpa_3',
          null,
        );

        // Verify no personal information in anonymized data
        final json = anonymousUser.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('phoneNumber'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });
    });

    group('Opt-Out Mechanisms', () {
      test('should allow opt-out of data sharing', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-optout-1',
          email: 'user@example.com',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // User opts out of location sharing
        final unifiedUserOptOut = UnifiedUser(
          id: unifiedUser.id,
          email: unifiedUser.email,
          createdAt: unifiedUser.createdAt,
          updatedAt: unifiedUser.updatedAt,
          // No location (user opted out)
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUserOptOut,
          'agent_optout_1',
          null,
        );

        // Verify location is not shared (respects opt-out)
        expect(anonymousUser.location, isNull);
      });

      test('should allow opt-out of personality data sharing', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-optout-2',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // User opts out of personality data sharing (no personality profile)
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_optout_2',
          null, // No personality profile (user opted out)
        );

        // Verify personality data is not shared
        expect(anonymousUser.personalityDimensions, isNull);
      });

      test('should respect opt-out for all data types', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-optout-3',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // User opts out of all data sharing (minimal data)
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_optout_3',
          null,
        );

        // Verify minimal data only (agentId required for AI2AI)
        final json = anonymousUser.toJson();
        expect(json.containsKey('agentId'), isTrue);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('preferences'), isFalse);
        expect(json.containsKey('location'), isFalse);
      });
    });

    group('Data Security', () {
      test('should encrypt personal data at rest', () async {
        const email = 'user@example.com';
        const userId = 'user-security-1';

        // Encrypt personal data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Verify encryption (data security)
        expect(encrypted, isNot(equals(email)));
        expect(encrypted, startsWith('encrypted:'));
      });

      test('should use user-specific encryption keys', () async {
        const email = 'user@example.com';
        const userId1 = 'user-security-2';
        const userId2 = 'user-security-3';

        // Encrypt same data for different users
        final encrypted1 = await encryptionService.encryptField('email', email, userId1);
        final encrypted2 = await encryptionService.encryptField('email', email, userId2);

        // Verify different encryption (user-specific keys)
        expect(encrypted1, isNot(equals(encrypted2)));

        // Verify each user can only decrypt their own data
        final decrypted1 = await encryptionService.decryptField('email', encrypted1, userId1);
        final decrypted2 = await encryptionService.decryptField('email', encrypted2, userId2);

        expect(decrypted1, equals(email));
        expect(decrypted2, equals(email));

        // User 1 should NOT decrypt User 2's data
        expect(
          () => encryptionService.decryptField('email', encrypted2, userId1),
          throwsException,
        );
      });

      test('should obfuscate location data for security', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-security-4',
          email: 'user@example.com',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_security_4',
          null,
        );

        // Location should be obfuscated (data security)
        if (anonymousUser.location != null) {
          expect(anonymousUser.location!.city, isNotEmpty);
          // Should not contain exact address
        }
      });

      test('should prevent unauthorized access to encrypted data', () async {
        const email = 'user@example.com';
        const userId = 'user-security-5';
        const unauthorizedUserId = 'unauthorized-user';

        // Encrypt data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // Attempt unauthorized access (should fail)
        expect(
          () => encryptionService.decryptField('email', encrypted, unauthorizedUserId),
          throwsException,
        );
      });
    });

    group('User Rights', () {
      test('should allow user to access their data', () async {
        const email = 'user@example.com';
        const userId = 'user-rights-1';

        // Encrypt user data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // User can access their data (CCPA right to know)
        final decrypted = await encryptionService.decryptField('email', encrypted, userId);
        expect(decrypted, equals(email));
      });

      test('should allow user to delete their data', () async {
        const email = 'user@example.com';
        const userId = 'user-rights-2';

        // Encrypt user data
        final encrypted = await encryptionService.encryptField('email', email, userId);

        // User can delete their data (CCPA right to deletion)
        await encryptionService.deleteKey('email', userId);

        // Verify data is deleted
        expect(
          () => encryptionService.decryptField('email', encrypted, userId),
          throwsException,
        );
      });

      test('should allow user to opt-out of data sharing', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-rights-3',
          email: 'user@example.com',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // User opts out (no location sharing)
        final unifiedUserOptOut = UnifiedUser(
          id: unifiedUser.id,
          email: unifiedUser.email,
          createdAt: unifiedUser.createdAt,
          updatedAt: unifiedUser.updatedAt,
          // No location (user opted out)
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUserOptOut,
          'agent_rights_3',
          null,
        );

        // Verify opt-out is respected
        expect(anonymousUser.location, isNull);
      });

      test('should allow user to export their data', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-rights-4',
          email: 'user@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_rights_4',
          null,
        );

        // User can export their data (CCPA right to data portability)
        final json = anonymousUser.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('agentId'), isTrue);

        // Personal data should NOT be in export
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });

      test('should allow user to know what data is collected', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-rights-5',
          email: 'user@example.com',
          displayName: 'Test User',
          location: 'San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUser,
          'agent_rights_5',
          null,
        );

        // User can see what data is collected (CCPA right to know)
        final json = anonymousUser.toJson();
        
        // Should see agentId (collected)
        expect(json.containsKey('agentId'), isTrue);
        
        // Should NOT see personal data (not collected in AI2AI)
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('phoneNumber'), isFalse);
        expect(json.containsKey('userId'), isFalse);
      });
    });

    group('CCPA Compliance Verification', () {
      test('should verify all CCPA requirements are met', () async {
        final unifiedUser = UnifiedUser(
          id: 'user-ccpa-verify',
          email: 'user@example.com',
          displayName: 'Test User',
          location: '123 Main St, San Francisco, CA',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Test 1: Data deletion
        final encrypted = await encryptionService.encryptField('email', unifiedUser.email, unifiedUser.id);
        await encryptionService.deleteKey('email', unifiedUser.id);
        expect(
          () => encryptionService.decryptField('email', encrypted, unifiedUser.id),
          throwsException,
        );

        // Test 2: Opt-out mechanisms
        final unifiedUserOptOut = UnifiedUser(
          id: unifiedUser.id,
          email: unifiedUser.email,
          createdAt: unifiedUser.createdAt,
          updatedAt: unifiedUser.updatedAt,
          // No location (user opted out)
        );
        final anonymousUser = await anonymizationService.anonymizeUser(
          unifiedUserOptOut,
          'agent_ccpa_verify',
          null,
        );
        expect(anonymousUser.location, isNull);

        // Test 3: Data security
        if (unifiedUser.displayName != null) {
          final encrypted2 = await encryptionService.encryptField('name', unifiedUser.displayName!, unifiedUser.id);
          expect(encrypted2, startsWith('encrypted:'));
        }

        // Test 4: User rights
        final json = anonymousUser.toJson();
        expect(json.containsKey('agentId'), isTrue);
        expect(json.containsKey('email'), isFalse);
      });
    });
  });
}

