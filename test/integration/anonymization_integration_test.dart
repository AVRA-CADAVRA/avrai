import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/services/location_obfuscation_service.dart';
import 'package:spots/core/services/audit_log_service.dart';
import 'package:spots/core/ai2ai/anonymous_communication.dart';

/// Integration tests for anonymization services in AI2AI context
void main() {
  group('Anonymization Integration Tests', () {
    late UserAnonymizationService anonymizationService;
    late LocationObfuscationService locationService;
    late AuditLogService auditService;
    late AnonymousCommunicationProtocol protocol;

    setUp(() {
      locationService = LocationObfuscationService();
      anonymizationService = UserAnonymizationService(
        locationObfuscationService: locationService,
      );
      auditService = AuditLogService();
      protocol = AnonymousCommunicationProtocol();
    });

    test('end-to-end: UnifiedUser → AnonymousUser → AI2AI payload', () async {
      // Create UnifiedUser with personal data
      final unifiedUser = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'John Doe',
        location: 'Austin, TX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personality = PersonalityProfile.initial(agentId: 'agent-123');

      // Step 1: Anonymize user
      final anonymousUser = await anonymizationService.anonymizeUser(
        unifiedUser,
        'agent-123',
        personality,
        isAdmin: false,
      );

      // Step 2: Verify no personal data
      expect(anonymousUser.agentId, 'agent-123');
      expect(anonymousUser.toJson().containsKey('email'), false);
      expect(anonymousUser.toJson().containsKey('name'), false);
      expect(anonymousUser.toJson().containsKey('userId'), false);

      // Step 3: Create AI2AI payload
      final payload = anonymousUser.toJson();

      // Step 4: Validate payload passes anonymization check
      expect(
        () => protocol.sendEncryptedMessage(
          'agent-456',
          MessageType.discoverySync,
          payload,
        ),
        returnsNormally,
      );

      // Step 5: Verify audit log
      // (In production, would check database)
    });

    test('end-to-end: location obfuscation in AI2AI context', () async {
      // Set home location
      locationService.setHomeLocation('user-123', '123 Main St, Austin, TX');

      // Try to obfuscate home location (should fail)
      expect(
        () => locationService.obfuscateLocation(
          '123 Main St, Austin, TX',
          'user-123',
          isAdmin: false,
        ),
        throwsException,
      );

      // Obfuscate non-home location (should succeed)
      final obfuscated = await locationService.obfuscateLocation(
        '500 Congress Ave, Austin, TX',
        'user-123',
        isAdmin: false,
      );

      expect(obfuscated.city, 'Austin');
      expect(obfuscated.latitude, isNotNull);
      expect(obfuscated.longitude, isNotNull);
    });

    test('end-to-end: admin/godmode allows exact locations', () async {
      final obfuscated = await locationService.obfuscateLocation(
        'Austin, TX',
        'user-123',
        isAdmin: true, // Admin mode
        exactLatitude: 30.2672,
        exactLongitude: -97.7431,
      );

      // Admin should get exact coordinates
      expect(obfuscated.latitude, 30.2672);
      expect(obfuscated.longitude, -97.7431);
    });

    test('end-to-end: audit logging for anonymization', () async {
      final unifiedUser = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Anonymize user
      final anonymousUser = await anonymizationService.anonymizeUser(
        unifiedUser,
        'agent-123',
        null,
      );

      // Log anonymization (should not throw)
      await auditService.logAnonymization(
        unifiedUser.id,
        anonymousUser.agentId,
      );

      // Log data access
      await auditService.logDataAccess(
        unifiedUser.id,
        'email',
        'read',
      );

      // Should complete without errors
      expect(anonymousUser.agentId, 'agent-123');
    });

    test('end-to-end: validation blocks personal data in AI2AI', () async {
      // Try to send payload with personal data
      final badPayload = {
        'userId': 'user-123',
        'email': 'user@example.com',
        'data': 'some data',
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          badPayload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });

    test('end-to-end: nested personal data detection', () async {
      // Try to send payload with nested personal data
      final badPayload = {
        'user': {
          'profile': {
            'email': 'user@example.com',
          },
        },
      };

      expect(
        () => protocol.sendEncryptedMessage(
          'agent-123',
          MessageType.discoverySync,
          badPayload,
        ),
        throwsA(isA<AnonymousCommunicationException>()),
      );
    });
  });
}

