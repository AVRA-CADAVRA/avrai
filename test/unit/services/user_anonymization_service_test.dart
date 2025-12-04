import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots/core/models/personality_profile.dart';

void main() {
  group('UserAnonymizationService', () {
    late UserAnonymizationService service;

    setUp(() {
      service = UserAnonymizationService();
    });

    test('should create AnonymousUser from UnifiedUser', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        displayName: 'John Doe',
        location: 'Austin, TX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personality = PersonalityProfile.initial(agentId: 'agent-123');

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent-123',
        personality,
      );

      expect(anonymousUser.agentId, 'agent-123');
      expect(anonymousUser.personalityDimensions, personality);
      // Should not contain personal data
      expect(anonymousUser.toJson().containsKey('email'), false);
      expect(anonymousUser.toJson().containsKey('name'), false);
      expect(anonymousUser.toJson().containsKey('userId'), false);
    });

    test('should throw if agentId is invalid', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => service.anonymizeUser(user, 'invalid-id', null),
        throwsException,
      );
    });

    test('should validate AnonymousUser has no personal data', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent-123',
        null,
      );

      // Should not throw
      anonymousUser.validateNoPersonalData();
    });

    test('should handle location obfuscation', () async {
      final user = UnifiedUser(
        id: 'user-123',
        email: 'user@example.com',
        location: 'Austin, TX',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final anonymousUser = await service.anonymizeUser(
        user,
        'agent-123',
        null,
      );

      // Location should be obfuscated (city-level only)
      expect(anonymousUser.location, isNotNull);
      expect(anonymousUser.location!.city, isNotEmpty);
    });
  });
}
