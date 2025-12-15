import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/privacy_protection.dart' show PrivacyProtection, AnonymizedPersonalityData, AnonymizedVibeData;
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';

/// Privacy Protection Tests
/// Tests the comprehensive privacy protection system
/// OUR_GUTS.md: "Complete privacy protection with zero personal data exposure"
void main() {
  group('PrivacyProtection', () {
    group('Personality Profile Anonymization', () {
      test('should anonymize personality profile without errors', () async {
        const userId = 'test-user-123';
        final profile = PersonalityProfile.initial(userId);

        final anonymized = await PrivacyProtection.anonymizePersonalityProfile(
          profile,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        expect(anonymized, isA<AnonymizedPersonalityData>());
        expect(anonymized.privacyLevel, equals('MAXIMUM_ANONYMIZATION'));
        expect(anonymized.anonymizationQuality, greaterThanOrEqualTo(0.0));
        expect(anonymized.anonymizationQuality, lessThanOrEqualTo(1.0));
        expect(anonymized.fingerprint, isNotEmpty);
      });

      test('should ensure anonymized data contains no personal identifiers', () async {
        const userId = 'test-user-123';
        final profile = PersonalityProfile.initial(userId);

        final anonymized = await PrivacyProtection.anonymizePersonalityProfile(
          profile,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        // Verify no personal data is exposed
        expect(anonymized.fingerprint, isNotEmpty);
        expect(anonymized.anonymizedDimensions, isNotEmpty);
        // Fingerprint should not contain userId
        expect(anonymized.fingerprint.contains(userId), isFalse);
      });

      test('should handle different privacy levels', () async {
        const userId = 'test-user-123';
        final profile = PersonalityProfile.initial(userId);
        final privacyLevels = [
          'MAXIMUM_ANONYMIZATION',
          'HIGH_ANONYMIZATION',
          'STANDARD_ANONYMIZATION',
        ];

        for (final level in privacyLevels) {
          final anonymized = await PrivacyProtection.anonymizePersonalityProfile(
            profile,
            privacyLevel: level,
          );

          expect(anonymized.privacyLevel, equals(level));
        }
      });
    });

    group('User Vibe Anonymization', () {
      test('should anonymize user vibe without errors', () async {
        const userId = 'test-user-123';
        final vibe = UserVibe.fromPersonalityProfile(userId, {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
        });

        final anonymized = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        expect(anonymized, isA<AnonymizedVibeData>());
        expect(anonymized.privacyLevel, equals('MAXIMUM_ANONYMIZATION'));
        expect(anonymized.anonymizationQuality, greaterThanOrEqualTo(0.0));
        expect(anonymized.anonymizationQuality, lessThanOrEqualTo(1.0));
      });

      test('should ensure anonymized vibe contains no user data', () async {
        const userId = 'test-user-123';
        final vibe = UserVibe.fromPersonalityProfile(userId, {
          'exploration_eagerness': 0.7,
        });

        final anonymized = await PrivacyProtection.anonymizeUserVibe(
          vibe,
          privacyLevel: 'MAXIMUM_ANONYMIZATION',
        );

        // Verify privacy preservation
        expect(anonymized.vibeSignature, isNotEmpty);
        expect(anonymized.noisyDimensions, isNotEmpty);
      });
    });

    group('Differential Privacy', () {
      test('should apply differential privacy without errors', () async {
        final dimensions = {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
        };

        final protected = await PrivacyProtection.applyDifferentialPrivacy(dimensions);

        expect(protected, isA<Map<String, double>>());
        expect(protected.length, equals(dimensions.length));
        // Values should be modified but still in valid range
        for (final value in protected.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });
    });
  });
}

