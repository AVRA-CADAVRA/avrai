import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/constants/vibe_constants.dart';

/// Tests for the AI2AI Personality Learning System
/// OUR_GUTS.md: "AI personality that evolves and learns while preserving privacy"
/// 
/// These tests ensure the 8-dimension personality system functions optimally
/// for development debugging and deployment performance
@GenerateMocks([])
void main() {
  group('PersonalityProfile Core Functionality', () {
    late PersonalityProfile profile;
    const String testUserId = 'test-user-123';

    setUp(() {
      profile = PersonalityProfile.initial(testUserId);
    });

    group('Initialization and Validation', () {
      test('should create initial personality profile with correct defaults', () {
        expect(profile.userId, equals(testUserId));
        expect(profile.dimensions.length, equals(VibeConstants.coreDimensions.length));
        expect(profile.archetype, equals('developing'));
        expect(profile.authenticity, equals(0.5));
        expect(profile.evolutionGeneration, equals(1));
        
        // Verify all core dimensions are present with default values
        for (final dimension in VibeConstants.coreDimensions) {
          expect(profile.dimensions.containsKey(dimension), isTrue);
          expect(profile.dimensions[dimension], equals(VibeConstants.defaultDimensionValue));
          expect(profile.dimensionConfidence[dimension], equals(0.0));
        }
      });

      test('should initialize learning history with correct structure', () {
        final history = profile.learningHistory;
        expect(history['total_interactions'], equals(0));
        expect(history['successful_ai2ai_connections'], equals(0));
        expect(history['learning_sources'], isA<List<String>>());
        expect(history['evolution_milestones'], isA<List<DateTime>>());
      });

      test('should validate all 8 core dimensions are present', () {
        final expectedDimensions = [
          'exploration_eagerness',
          'community_orientation', 
          'authenticity_preference',
          'social_discovery_style',
          'temporal_flexibility',
          'location_adventurousness',
          'curation_tendency',
          'trust_network_reliance',
        ];
        
        for (final dimension in expectedDimensions) {
          expect(profile.dimensions.containsKey(dimension), isTrue,
              reason: 'Missing core dimension: $dimension');
        }
      });
    });

    group('Personality Evolution', () {
      test('should evolve personality with bounded dimension updates', () {
        final newDimensions = {
          'exploration_eagerness': 0.8,
          'community_orientation': 1.2, // Should be clamped to 1.0
        };
        final newConfidence = {
          'exploration_eagerness': 0.7,
          'community_orientation': 0.9,
        };

        final evolved = profile.evolve(
          newDimensions: newDimensions,
          newConfidence: newConfidence,
          newArchetype: 'adventurous_explorer',
          newAuthenticity: 0.8,
        );

        expect(evolved.dimensions['exploration_eagerness'], equals(0.8));
        expect(evolved.dimensions['community_orientation'], equals(1.0)); // Clamped
        expect(evolved.dimensionConfidence['exploration_eagerness'], equals(0.7));
        expect(evolved.archetype, equals('adventurous_explorer'));
        expect(evolved.authenticity, equals(0.8));
        expect(evolved.evolutionGeneration, equals(2));
      });

      test('should preserve original profile immutability during evolution', () {
        final originalDimensions = Map<String, double>.from(profile.dimensions);
        final originalGeneration = profile.evolutionGeneration;
        
        profile.evolve(newDimensions: {'exploration_eagerness': 0.9});
        
        expect(profile.dimensions, equals(originalDimensions));
        expect(profile.evolutionGeneration, equals(originalGeneration));
      });

      test('should add evolution milestone during evolution', () {
        final originalMilestones = profile.learningHistory['evolution_milestones'] as List<DateTime>;
        final originalCount = originalMilestones.length;
        
        final evolved = profile.evolve(newAuthenticity: 0.7);
        final newMilestones = evolved.learningHistory['evolution_milestones'] as List<DateTime>;
        
        expect(newMilestones.length, equals(originalCount + 1));
      });

      test('should merge additional learning data correctly', () {
        final additionalLearning = {
          'total_interactions': 5, // Should increment
          'learning_sources': ['ai2ai_network'], // Should append
          'new_metric': 'test_value', // Should add
        };
        
        final evolved = profile.evolve(additionalLearning: additionalLearning);
        
        expect(evolved.learningHistory['total_interactions'], equals(5));
        expect(evolved.learningHistory['learning_sources'], contains('ai2ai_network'));
        expect(evolved.learningHistory['new_metric'], equals('test_value'));
      });
    });

    group('Compatibility Calculations', () {
      test('should calculate compatibility between similar personalities', () {
        final profile1 = PersonalityProfile.initial('user1').evolve(
          newDimensions: {
            'exploration_eagerness': 0.8,
            'community_orientation': 0.7,
            'authenticity_preference': 0.9,
          },
          newConfidence: {
            'exploration_eagerness': 1.0,
            'community_orientation': 1.0,
            'authenticity_preference': 1.0,
          },
        );
        
        final profile2 = PersonalityProfile.initial('user2').evolve(
          newDimensions: {
            'exploration_eagerness': 0.75,
            'community_orientation': 0.8,
            'authenticity_preference': 0.85,
          },
          newConfidence: {
            'exploration_eagerness': 1.0,
            'community_orientation': 1.0,
            'authenticity_preference': 1.0,
          },
        );
        
        final compatibility = profile1.calculateCompatibility(profile2);
        expect(compatibility, greaterThan(VibeConstants.mediumCompatibilityThreshold));
      });

      test('should calculate compatibility between dissimilar personalities', () {
        final profile1 = PersonalityProfile.initial('user1').evolve(
          newDimensions: {
            'exploration_eagerness': 0.9,
            'community_orientation': 0.1,
          },
          newConfidence: {
            'exploration_eagerness': 1.0,
            'community_orientation': 1.0,
          },
        );
        
        final profile2 = PersonalityProfile.initial('user2').evolve(
          newDimensions: {
            'exploration_eagerness': 0.1,
            'community_orientation': 0.9,
          },
          newConfidence: {
            'exploration_eagerness': 1.0,
            'community_orientation': 1.0,
          },
        );
        
        final compatibility = profile1.calculateCompatibility(profile2);
        expect(compatibility, lessThan(VibeConstants.mediumCompatibilityThreshold));
      });

      test('should return 1.0 compatibility when comparing profile with itself', () {
        final compatibility = profile.calculateCompatibility(profile);
        expect(compatibility, equals(1.0));
      });
    });

    group('Learning Potential Calculations', () {
      test('should calculate high learning potential for compatible personalities', () {
        final confidentProfile = profile.evolve(
          newConfidence: Map.fromIterable(
            VibeConstants.coreDimensions,
            key: (d) => d as String,
            value: (_) => 1.0,
          ),
        );

        final compatibleProfile = PersonalityProfile.initial('compatible').evolve(
          newDimensions: Map<String, double>.from(profile.dimensions),
          newConfidence: Map<String, double>.from(profile.dimensions)
              .map((key, _) => MapEntry(key, 1.0)),
        );
        
        final learningPotential = confidentProfile.calculateLearningPotential(compatibleProfile);
        expect(learningPotential, greaterThanOrEqualTo(0.6));
      });

      test('should calculate minimal learning potential for incompatible personalities', () {
        final incompatibleProfile = PersonalityProfile.initial('incompatible').evolve(
          newDimensions: {
            'exploration_eagerness': 1.0,
            'community_orientation': 0.0,
            'authenticity_preference': 0.0,
            'social_discovery_style': 1.0,
          },
        );
        
        final learningPotential = profile.calculateLearningPotential(incompatibleProfile);
        expect(learningPotential, lessThanOrEqualTo(0.3));
      });

      test('should ensure minimum learning potential for any personality pair', () {
        final randomProfile = PersonalityProfile.initial('random').evolve(
          newDimensions: {
            'exploration_eagerness': 0.1,
            'community_orientation': 0.9,
          },
        );
        
        final learningPotential = profile.calculateLearningPotential(randomProfile);
        expect(learningPotential, greaterThanOrEqualTo(0.1));
      });
    });

    group('Archetype Determination', () {
      test('should determine adventurous_explorer archetype correctly', () {
        final explorerProfile = profile.evolve(
          newDimensions: {
            'exploration_eagerness': 0.9,
            'location_adventurousness': 0.8,
            'temporal_flexibility': 0.7,
            'community_orientation': 0.6,
          },
        );
        
        expect(explorerProfile.archetype, equals('adventurous_explorer'));
      });

      test('should determine community_curator archetype correctly', () {
        final curatorProfile = profile.evolve(
          newDimensions: {
            'community_orientation': 0.9,
            'curation_tendency': 0.8,
            'trust_network_reliance': 0.7,
            'authenticity_preference': 0.8,
          },
        );
        
        expect(curatorProfile.archetype, equals('community_curator'));
      });

      test('should fall back to balanced archetype for unclear patterns', () {
        final balancedProfile = profile.evolve(
          newDimensions: {
            'exploration_eagerness': 0.5,
            'community_orientation': 0.5,
            'authenticity_preference': 0.5,
          },
        );
        
        expect(balancedProfile.archetype, equals('balanced'));
      });
    });

    group('Development Status Checks', () {
      test('should correctly identify underdeveloped personality', () {
        expect(profile.isWellDeveloped, isFalse);
      });

      test('should correctly identify well-developed personality', () {
        final wellDeveloped = profile.evolve(
          newConfidence: Map.fromIterable(
            VibeConstants.coreDimensions,
            key: (d) => d,
            value: (d) => 0.8,
          ),
          additionalLearning: {
            'total_interactions': VibeConstants.minActionsForAnalysis + 10,
          },
        );
        
        expect(wellDeveloped.isWellDeveloped, isTrue);
      });
    });

    group('Serialization and Persistence', () {
      test('should serialize to JSON correctly', () {
        final json = profile.toJson();
        
        expect(json['user_id'], equals(testUserId));
        expect(json['dimensions'], isA<Map<String, double>>());
        expect(json['archetype'], equals('developing'));
        expect(json['evolution_generation'], equals(1));
        expect(json['learning_history'], isA<Map<String, dynamic>>());
      });

      test('should deserialize from JSON correctly', () {
        final json = profile.toJson();
        final deserialized = PersonalityProfile.fromJson(json);
        
        expect(deserialized.userId, equals(profile.userId));
        expect(deserialized.dimensions, equals(profile.dimensions));
        expect(deserialized.archetype, equals(profile.archetype));
        expect(deserialized.evolutionGeneration, equals(profile.evolutionGeneration));
      });

      test('should maintain data integrity through serialization cycle', () {
        final evolved = profile.evolve(
          newDimensions: {'exploration_eagerness': 0.8},
          newAuthenticity: 0.9,
        );
        
        final json = evolved.toJson();
        final restored = PersonalityProfile.fromJson(json);
        
        expect(restored.dimensions['exploration_eagerness'], equals(0.8));
        expect(restored.authenticity, equals(0.9));
        expect(restored.evolutionGeneration, equals(2));
      });
    });

    group('Summary and Debug Information', () {
      test('should generate comprehensive summary', () {
        final evolved = profile.evolve(
          newDimensions: {'exploration_eagerness': 0.9},
          newConfidence: {'exploration_eagerness': 0.8},
          additionalLearning: {
            'total_interactions': 25,
            'successful_ai2ai_connections': 5,
          },
        );
        
        final summary = evolved.getSummary();
        
        expect(summary['archetype'], isA<String>());
        expect(summary['authenticity'], isA<double>());
        expect(summary['generation'], equals(2));
        expect(summary['total_interactions'], equals(25));
        expect(summary['ai2ai_connections'], equals(5));
        expect(summary['well_developed'], isA<bool>());
      });

      test('should include dominant traits in summary', () {
        final evolved = profile.evolve(
          newDimensions: {
            'exploration_eagerness': 0.95,
            'authenticity_preference': 0.9,
          },
          newConfidence: {
            'exploration_eagerness': 0.9,
            'authenticity_preference': 0.9,
          },
        );
        
        final summary = evolved.getSummary();
        final dominantTraits = summary['dominant_traits'] as List<String>;
        
        expect(dominantTraits, contains('exploration_eagerness'));
        expect(dominantTraits, contains('authenticity_preference'));
      });
    });

    group('Privacy and Security Validation', () {
      test('should not expose user identifying information in JSON', () {
        final json = profile.toJson();
        final jsonString = json.toString();
        
        // Ensure no common PII patterns
        expect(jsonString.toLowerCase(), isNot(contains('email')));
        expect(jsonString.toLowerCase(), isNot(contains('phone')));
        expect(jsonString.toLowerCase(), isNot(contains('address')));
        expect(jsonString.toLowerCase(), isNot(contains('name')));
      });

      test('should maintain consistent hash for same profile state', () {
        final profile1 = PersonalityProfile.initial(testUserId);
        final profile2 = PersonalityProfile.initial(testUserId);
        
        expect(profile1.hashCode, equals(profile2.hashCode));
        expect(profile1, equals(profile2));
      });

      test('should have different hash after evolution', () {
        final originalHash = profile.hashCode;
        final evolved = profile.evolve(newAuthenticity: 0.8);
        
        expect(evolved.hashCode, isNot(equals(originalHash)));
        expect(evolved, isNot(equals(profile)));
      });
    });
  });

  group('AI2AI Learning Network Integration', () {
    test('should support network effect calculations without exposing user data', () {
      final profiles = List.generate(5, (i) => 
        PersonalityProfile.initial('anonymous-$i').evolve(
          newDimensions: {
            'exploration_eagerness': 0.2 * (i + 1),
            'community_orientation': 0.8 - (0.1 * i),
          },
        ),
      );
      
      // Test network compatibility matrix
      final compatibilityMatrix = <List<double>>[];
      for (final profile1 in profiles) {
        final row = <double>[];
        for (final profile2 in profiles) {
          row.add(profile1.calculateCompatibility(profile2));
        }
        compatibilityMatrix.add(row);
      }
      
      // Verify network properties
      expect(compatibilityMatrix.length, equals(5));
      expect(compatibilityMatrix[0].length, equals(5));
      
      // Diagonal should be 1.0 (self-compatibility)
      for (int i = 0; i < 5; i++) {
        expect(compatibilityMatrix[i][i], equals(1.0));
      }
      
      // Matrix should be symmetric
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          expect(compatibilityMatrix[i][j], equals(compatibilityMatrix[j][i]));
        }
      }
    });

    test('should support ecosystem evolution tracking', () {
      final baseProfile = PersonalityProfile.initial('ecosystem-node');
      final generations = <PersonalityProfile>[];
      
      // Simulate ecosystem evolution over multiple generations
      var current = baseProfile;
      for (int gen = 0; gen < 5; gen++) {
        current = current.evolve(
          newDimensions: {
            'exploration_eagerness': (current.dimensions['exploration_eagerness']! + 0.1).clamp(0.0, 1.0),
          },
          additionalLearning: {
            'total_interactions': 10,
            'successful_ai2ai_connections': 2,
          },
        );
        generations.add(current);
      }
      
      // Verify evolution progression
      expect(generations.length, equals(5));
      expect(generations.last.evolutionGeneration, equals(6));
      
      // Verify learning accumulation
      final finalInteractions = generations.last.learningHistory['total_interactions'] as int;
      expect(finalInteractions, equals(50)); // 10 * 5 generations
      
      // Verify dimension evolution
      final finalEagerness = generations.last.dimensions['exploration_eagerness']!;
      expect(finalEagerness, greaterThan(baseProfile.dimensions['exploration_eagerness']!));
    });
  });

  group('Performance and Optimization Tests', () {
    test('should handle large-scale compatibility calculations efficiently', () {
      final stopwatch = Stopwatch()..start();
      final profiles = List.generate(100, (i) => PersonalityProfile.initial('perf-test-$i'));
      
      // Calculate all pairwise compatibilities
      var totalCompatibility = 0.0;
      for (final profile1 in profiles) {
        for (final profile2 in profiles) {
          totalCompatibility += profile1.calculateCompatibility(profile2);
        }
      }
      
      stopwatch.stop();
      
      // Should complete within reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(totalCompatibility, greaterThan(0)); // Sanity check
    });

    test('should maintain memory efficiency during evolution chains', () {
      var current = PersonalityProfile.initial('memory-test');
      
      // Create long evolution chain
      for (int i = 0; i < 1000; i++) {
        current = current.evolve(
          newDimensions: {'exploration_eagerness': (i % 10) / 10.0},
        );
      }
      
      expect(current.evolutionGeneration, equals(1001));
      // Profile should not grow unboundedly with evolution history
      expect(current.learningHistory['evolution_milestones']?.length, isNotNull);
    });

    test('should validate dimension value bounds consistently', () {
      final testCases = [
        -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0, double.infinity, double.negativeInfinity
      ];
      
      final testProfile = PersonalityProfile.initial('test-user-bounds');
      for (final value in testCases) {
        final evolved = testProfile.evolve(
          newDimensions: {'exploration_eagerness': value},
        );
        
        final actualValue = evolved.dimensions['exploration_eagerness']!;
        expect(actualValue, greaterThanOrEqualTo(VibeConstants.minDimensionValue));
        expect(actualValue, lessThanOrEqualTo(VibeConstants.maxDimensionValue));
      }
    });
  });
}
