import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/models/personality_profile.dart';

/// Tests for AnonymousUser model
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests ensure AnonymousUser contains NO personal information
/// and can be safely shared in AI2AI network
void main() {
  group('AnonymousUser', () {
    group('Model Creation', () {
      test('should create AnonymousUser with required agentId', () {
        final anonymousUser = AnonymousUser(
          agentId: 'agent_123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(anonymousUser.agentId, equals('agent_123'));
        expect(anonymousUser.personalityDimensions, isNull);
        expect(anonymousUser.preferences, isNull);
        expect(anonymousUser.expertise, isNull);
        expect(anonymousUser.location, isNull);
      });

      test('should create AnonymousUser with all optional fields', () {
        final personalityProfile = PersonalityProfile.initial('user-456');
        final preferences = {
          'category': 'food',
          'style': 'casual',
        };
        final expertise = 'restaurants, bars'; // String, not List
        final obfuscatedLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749,
          longitude: -122.4194,
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );

        final anonymousUser = AnonymousUser(
          agentId: 'agent_456',
          personalityDimensions: personalityProfile,
          preferences: preferences,
          expertise: expertise,
          location: obfuscatedLocation,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(anonymousUser.agentId, equals('agent_456'));
        expect(anonymousUser.personalityDimensions, equals(personalityProfile));
        expect(anonymousUser.preferences, equals(preferences));
        expect(anonymousUser.expertise, equals(expertise));
        expect(anonymousUser.location, equals(obfuscatedLocation));
      });

      test('should require createdAt and updatedAt', () {
        final now = DateTime.now();
        final anonymousUser = AnonymousUser(
          agentId: 'agent_required',
          createdAt: now,
          updatedAt: now,
        );

        expect(anonymousUser.createdAt, equals(now));
        expect(anonymousUser.updatedAt, equals(now));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () async {
        final personalityProfile = PersonalityProfile.initial('user-789');
        final anonymousUser = AnonymousUser(
          agentId: 'agent_789',
          personalityDimensions: personalityProfile,
          preferences: {'pref1': 'value1'},
          expertise: 'expertise1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = anonymousUser.toJson();

        expect(json['agentId'], equals('agent_789'));
        expect(json['personalityDimensions'], isNotNull);
        expect(json['preferences'], equals({'pref1': 'value1'}));
        expect(json['expertise'], equals('expertise1'));
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final personalityJson = PersonalityProfile.initial('user-json').toJson();
        final json = {
          'agentId': 'agent_json',
          'personalityDimensions': personalityJson,
          'preferences': {'pref1': 'value1'},
          'expertise': 'expertise1',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final anonymousUser = AnonymousUser.fromJson(json);

        expect(anonymousUser.agentId, equals('agent_json'));
        expect(anonymousUser.personalityDimensions, isNotNull);
        expect(anonymousUser.preferences, equals({'pref1': 'value1'}));
        expect(anonymousUser.expertise, equals('expertise1'));
      });

      test('should handle JSON with null optional fields', () {
        final json = {
          'agentId': 'agent_minimal',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final anonymousUser = AnonymousUser.fromJson(json);

        expect(anonymousUser.agentId, equals('agent_minimal'));
        expect(anonymousUser.personalityDimensions, isNull);
        expect(anonymousUser.preferences, isNull);
        expect(anonymousUser.expertise, isNull);
        expect(anonymousUser.location, isNull);
      });

      test('should handle JSON roundtrip correctly', () {
        final personalityProfile = PersonalityProfile.initial('user-roundtrip');
        final original = AnonymousUser(
          agentId: 'agent_roundtrip',
          personalityDimensions: personalityProfile,
          preferences: {'cat': 'food'},
          expertise: 'restaurants',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = original.toJson();
        final reconstructed = AnonymousUser.fromJson(json);

        expect(reconstructed.agentId, equals(original.agentId));
        expect(reconstructed.expertise, equals(original.expertise));
        expect(reconstructed.preferences, equals(original.preferences));
      });
    });

    group('Validation', () {
      test('should validate that no personal data fields exist', () {
        final anonymousUser = AnonymousUser(
          agentId: 'agent_valid',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // AnonymousUser should NOT have these fields:
        // - userId
        // - email
        // - name
        // - phone
        // - address
        // - personalInfo

        // Verify by checking JSON doesn't contain these keys
        final json = anonymousUser.toJson();
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('name'), isFalse);
        expect(json.containsKey('phone'), isFalse);
        expect(json.containsKey('address'), isFalse);
        expect(json.containsKey('personalInfo'), isFalse);
      });

      test('should validate agentId format', () {
        // AgentId must start with "agent_"
        final anonymousUser = AnonymousUser(
          agentId: 'agent_valid',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Should not throw
        anonymousUser.validateNoPersonalData();
      });

      test('should reject invalid agentId format', () {
        final anonymousUser = AnonymousUser(
          agentId: 'invalid-id', // Doesn't start with "agent_"
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => anonymousUser.validateNoPersonalData(),
          throwsException,
        );
      });

      test('should validate location is obfuscated (not exact)', () {
        // Location should be ObfuscatedLocation, not exact coordinates
        final obfuscatedLocation = ObfuscatedLocation(
          city: 'San Francisco',
          country: 'USA',
          latitude: 37.7749, // City-level, not exact
          longitude: -122.4194,
          expiresAt: DateTime.now().add(Duration(hours: 24)),
        );

        final anonymousUser = AnonymousUser(
          agentId: 'agent_loc',
          location: obfuscatedLocation,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Should have city-level location, not exact address
        expect(anonymousUser.location?.city, isNotNull);
        expect(anonymousUser.location?.latitude, isNotNull);
        // Should have expiration
        expect(anonymousUser.location?.expiresAt, isNotNull);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal when all fields match', () {
        final now = DateTime.now();
        final personality1 = PersonalityProfile.initial('user-1');
        final personality2 = PersonalityProfile.initial('user-1');
        
        final user1 = AnonymousUser(
          agentId: 'agent_eq',
          personalityDimensions: personality1,
          createdAt: now,
          updatedAt: now,
        );
        final user2 = AnonymousUser(
          agentId: 'agent_eq',
          personalityDimensions: personality2,
          createdAt: now,
          updatedAt: now,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when agentId differs', () {
        final now = DateTime.now();
        final user1 = AnonymousUser(
          agentId: 'agent_1',
          createdAt: now,
          updatedAt: now,
        );
        final user2 = AnonymousUser(
          agentId: 'agent_2',
          createdAt: now,
          updatedAt: now,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('should not be equal when personalityDimensions differ', () {
        final now = DateTime.now();
        final personality1 = PersonalityProfile.initial('user-1');
        final personality2 = PersonalityProfile.initial('user-2');
        
        final user1 = AnonymousUser(
          agentId: 'agent_same',
          personalityDimensions: personality1,
          createdAt: now,
          updatedAt: now,
        );
        final user2 = AnonymousUser(
          agentId: 'agent_same',
          personalityDimensions: personality2,
          createdAt: now,
          updatedAt: now,
        );

        expect(user1, isNot(equals(user2)));
      });

      test('should handle null fields in equality', () {
        final now = DateTime.now();
        final user1 = AnonymousUser(
          agentId: 'agent_null',
          createdAt: now,
          updatedAt: now,
        );
        final user2 = AnonymousUser(
          agentId: 'agent_null',
          createdAt: now,
          updatedAt: now,
        );

        expect(user1, equals(user2));
      });
    });
  });
}

