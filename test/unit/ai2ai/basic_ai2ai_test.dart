import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/ai/privacy_protection.dart';

/// Basic AI2AI Personality Learning Test
/// OUR_GUTS.md: "Basic validation of AI2AI personality learning components"
void main() {
  group('Basic AI2AI Personality Learning Tests', () {
    test('should create personality profile with correct structure', () {
      final profile = PersonalityProfile.initial('test_user');
      
      expect(profile.userId, equals('test_user'));
      expect(profile.dimensions.length, equals(VibeConstants.coreDimensions.length));
      expect(profile.evolutionGeneration, equals(1));
      expect(profile.archetype, equals('developing'));
      
      // All dimensions should have default values
      for (final dimension in VibeConstants.coreDimensions) {
        expect(profile.dimensions[dimension], equals(VibeConstants.defaultDimensionValue));
      }
    });
    
    test('should evolve personality correctly', () {
      final initialProfile = PersonalityProfile.initial('test_user');
      
      final evolvedProfile = initialProfile.evolve(
        newDimensions: {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.7,
        },
        newConfidence: {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.7,
        },
        newAuthenticity: 0.8,
      );
      
      expect(evolvedProfile.evolutionGeneration, equals(2));
      expect(evolvedProfile.dimensions['exploration_eagerness'], equals(0.8));
      expect(evolvedProfile.dimensions['community_orientation'], equals(0.7));
      expect(evolvedProfile.authenticity, equals(0.8));
    });
    
    test('should calculate personality compatibility', () {
      final profile1 = PersonalityProfile.initial('user1').evolve(
        newDimensions: {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.7,
        },
        newConfidence: {
          'exploration_eagerness': 0.8,
          'community_orientation': 0.7,
        },
      );
      
      final profile2 = PersonalityProfile.initial('user2').evolve(
        newDimensions: {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.8,
        },
        newConfidence: {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.8,
        },
      );
      
      final compatibility = profile1.calculateCompatibility(profile2);
      
      expect(compatibility, greaterThan(0.5)); // Should be compatible
      expect(compatibility, lessThanOrEqualTo(1.0));
    });
    
    test('should create user vibe with proper anonymization', () {
      final testDimensions = {
        'exploration_eagerness': 0.8,
        'community_orientation': 0.7,
        'authenticity_preference': 0.9,
        'social_discovery_style': 0.6,
        'temporal_flexibility': 0.7,
        'location_adventurousness': 0.8,
        'curation_tendency': 0.5,
        'trust_network_reliance': 0.7,
      };
      
      final userVibe = UserVibe.fromPersonalityProfile('test_user', testDimensions);
      
      expect(userVibe.anonymizedDimensions.length, equals(testDimensions.length));
      expect(userVibe.overallEnergy, greaterThan(0.0));
      expect(userVibe.overallEnergy, lessThanOrEqualTo(1.0));
      expect(userVibe.socialPreference, greaterThan(0.0));
      expect(userVibe.socialPreference, lessThanOrEqualTo(1.0));
      expect(userVibe.explorationTendency, greaterThan(0.0));
      expect(userVibe.explorationTendency, lessThanOrEqualTo(1.0));
      expect(userVibe.hashedSignature.length, greaterThan(32));
    });
    
    test('should calculate vibe compatibility between users', () {
      final vibe1 = UserVibe.fromPersonalityProfile('user1', {
        'exploration_eagerness': 0.8,
        'community_orientation': 0.7,
        'authenticity_preference': 0.9,
        'social_discovery_style': 0.6,
        'temporal_flexibility': 0.7,
        'location_adventurousness': 0.8,
        'curation_tendency': 0.5,
        'trust_network_reliance': 0.7,
      });
      
      final vibe2 = UserVibe.fromPersonalityProfile('user2', {
        'exploration_eagerness': 0.7,
        'community_orientation': 0.8,
        'authenticity_preference': 0.8,
        'social_discovery_style': 0.7,
        'temporal_flexibility': 0.6,
        'location_adventurousness': 0.7,
        'curation_tendency': 0.6,
        'trust_network_reliance': 0.8,
      });
      
      final compatibility = vibe1.calculateVibeCompatibility(vibe2);
      
      expect(compatibility, greaterThan(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
      expect(compatibility, greaterThan(0.5)); // Should be compatible
    });
    
    test('should apply privacy protection with differential privacy', () async {
      final testData = {
        'dimension_1': 0.7,
        'dimension_2': 0.3,
        'dimension_3': 0.9,
      };
      
      final noisyData = await PrivacyProtection.applyDifferentialPrivacy(testData);
      
      expect(noisyData.length, equals(testData.length));
      for (final key in testData.keys) {
        expect(noisyData[key]!, greaterThanOrEqualTo(0.0));
        expect(noisyData[key]!, lessThanOrEqualTo(1.0));
      }
    });
    
    test('should create secure hash with proper entropy', () async {
      final testData = 'test_personality_data_12345';
      final salt = 'random_salt_67890';
      
      final hash = await PrivacyProtection.createSecureHash(testData, salt);
      
      expect(hash.length, greaterThan(32)); // SHA-256 produces long hashes
      expect(hash, isNot(contains(testData))); // Original data should not be in hash
      expect(hash, isNot(contains(salt))); // Salt should not be directly in hash
    });
    
    test('should enforce temporal decay for expired data', () async {
      final pastTime = DateTime.now().subtract(Duration(days: 35));
      final futureTime = DateTime.now().add(Duration(days: 25));
      
      // Test expired data
      final expiredValid = await PrivacyProtection.enforceTemporalDecay(
        pastTime, 
        pastTime.add(Duration(days: 30))
      );
      expect(expiredValid, isFalse);
      
      // Test valid data
      final validData = await PrivacyProtection.enforceTemporalDecay(
        DateTime.now(), 
        futureTime
      );
      expect(validData, isTrue);
    });
    
    test('should determine personality archetype correctly', () {
      // Test adventurous explorer archetype
      final explorerProfile = PersonalityProfile.initial('explorer').evolve(
        newDimensions: {
          'exploration_eagerness': 0.9,
          'location_adventurousness': 0.8,
          'temporal_flexibility': 0.7,
          'community_orientation': 0.6,
        },
      );
      
      final archetype = explorerProfile.archetype;
      expect(archetype, isA<String>());
      expect(archetype.isNotEmpty, isTrue);
    });
    
    test('should validate vibe constants are properly defined', () {
      // Verify core constants exist and are reasonable
      expect(VibeConstants.coreDimensions.length, equals(8));
      expect(VibeConstants.highCompatibilityThreshold, greaterThan(0.7));
      expect(VibeConstants.mediumCompatibilityThreshold, greaterThan(0.4));
      expect(VibeConstants.personalityLearningRate, greaterThan(0.0));
      expect(VibeConstants.personalityLearningRate, lessThan(1.0));
      expect(VibeConstants.maxSimultaneousConnections, greaterThan(0));
      expect(VibeConstants.vibeSignatureExpiryDays, greaterThan(0));
      
      // Verify all required dimensions are present
      final requiredDimensions = [
        'exploration_eagerness',
        'community_orientation', 
        'authenticity_preference',
        'social_discovery_style',
        'temporal_flexibility',
        'location_adventurousness',
        'curation_tendency',
        'trust_network_reliance',
      ];
      
      for (final dimension in requiredDimensions) {
        expect(VibeConstants.coreDimensions.contains(dimension), isTrue);
      }
    });
  });
}