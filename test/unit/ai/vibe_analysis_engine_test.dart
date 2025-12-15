import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/ai/vibe_analysis_engine.dart' show UserVibeAnalyzer, VibeCompatibilityResult;
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('UserVibeAnalyzer', () {
    late UserVibeAnalyzer analyzer;
    late SharedPreferencesCompat prefs;

    setUpAll(() async {
      await setupTestStorage();
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    setUp(() async {
      // Use in-memory storage-backed SharedPreferencesCompat for unit tests.
      prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(boxName: 'vibe_analysis_engine_test'),
      );
      analyzer = UserVibeAnalyzer(prefs: prefs);
    });

    group('Vibe Compilation', () {
      test('should compile user vibe without errors', () async {
        const userId = 'test-user-123';
        final profile = PersonalityProfile.initial(userId);

        final vibe = await analyzer.compileUserVibe(userId, profile);

        expect(vibe, isA<UserVibe>());
        // Privacy-preserving: UserVibe should not expose raw userId.
        expect(vibe.hashedSignature, isNotEmpty);
      });

      test('should handle different personality profiles', () async {
        const userId = 'test-user-123';
        final profile1 = PersonalityProfile.initial(userId);
        final profile2 = profile1.evolve(
          newDimensions: {'exploration_eagerness': 0.8},
          newConfidence: {'exploration_eagerness': 0.8},
          newAuthenticity: 0.8,
        );

        final vibe1 = await analyzer.compileUserVibe(userId, profile1);
        final vibe2 = await analyzer.compileUserVibe(userId, profile2);

        expect(vibe1, isA<UserVibe>());
        expect(vibe2, isA<UserVibe>());
      });
    });

    group('Vibe Compatibility Analysis', () {
      test('should analyze vibe compatibility without errors', () async {
        const userId1 = 'test-user-1';
        const userId2 = 'test-user-2';
        final vibe1 = UserVibe.fromPersonalityProfile(userId1, {
          'exploration_eagerness': 0.7,
        });
        final vibe2 = UserVibe.fromPersonalityProfile(userId2, {
          'exploration_eagerness': 0.8,
        });

        final result = await analyzer.analyzeVibeCompatibility(vibe1, vibe2);

        expect(result, isA<VibeCompatibilityResult>());
        expect(result.basicCompatibility, greaterThanOrEqualTo(0.0));
        expect(result.basicCompatibility, lessThanOrEqualTo(1.0));
      });

      test('should calculate AI pleasure potential', () async {
        const userId1 = 'test-user-1';
        const userId2 = 'test-user-2';
        final vibe1 = UserVibe.fromPersonalityProfile(userId1, {
          'exploration_eagerness': 0.7,
        });
        final vibe2 = UserVibe.fromPersonalityProfile(userId2, {
          'exploration_eagerness': 0.8,
        });

        final result = await analyzer.analyzeVibeCompatibility(vibe1, vibe2);

        expect(result.aiPleasurePotential, greaterThanOrEqualTo(0.0));
        expect(result.aiPleasurePotential, lessThanOrEqualTo(1.0));
      });
    });

    group('Privacy Validation', () {
      test('should ensure vibe compilation preserves privacy', () async {
        const userId = 'test-user-123';
        final profile = PersonalityProfile.initial(userId);

        final vibe = await analyzer.compileUserVibe(userId, profile);

        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        // Vibe should be compiled in a privacy-preserving way
        expect(vibe, isA<UserVibe>());
        expect(vibe.hashedSignature, isNotEmpty);
      });
    });
  });
}

