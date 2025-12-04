import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/platform_phase.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for PlatformPhase model
void main() {
  group('PlatformPhase Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create platform phase with required fields', () {
        final saturationFactors = SaturationFactors();
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.bootstrap,
          userCountThreshold: 1000,
          saturationFactors: saturationFactors,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(phase.id, equals('phase-1'));
        expect(phase.name, equals(PhaseName.bootstrap));
        expect(phase.userCountThreshold, equals(1000));
        expect(phase.categoryMultipliers, isEmpty);
        expect(phase.saturationFactors, equals(saturationFactors));
      });

      test('should create platform phase with category multipliers', () {
        final saturationFactors = SaturationFactors();
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          categoryMultipliers: {
            'Coffee': 1.5,
            'Food': 1.2,
          },
          saturationFactors: saturationFactors,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(phase.categoryMultipliers, hasLength(2));
        expect(phase.getCategoryMultiplier('Coffee'), equals(1.5));
        expect(phase.getCategoryMultiplier('Food'), equals(1.2));
        expect(phase.getCategoryMultiplier('Unknown'), equals(1.0));
      });
    });

    group('Phase Qualification', () {
      test('should qualify for phase when user count meets threshold', () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.bootstrap,
          userCountThreshold: 1000,
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(phase.qualifiesForPhase(1000), isTrue);
        expect(phase.qualifiesForPhase(1500), isTrue);
        expect(phase.qualifiesForPhase(999), isFalse);
      });
    });

    group('Category Multipliers', () {
      test('should return default multiplier for unknown category', () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.bootstrap,
          userCountThreshold: 1000,
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(phase.getCategoryMultiplier('Unknown'), equals(1.0));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final phase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          categoryMultipliers: {'Coffee': 1.5},
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = phase.toJson();

        expect(json['id'], equals('phase-1'));
        expect(json['name'], equals('growth'));
        expect(json['userCountThreshold'], equals(10000));
        expect(json['categoryMultipliers'], equals({'Coffee': 1.5}));
        expect(json['saturationFactors'], isNotNull);
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'phase-1',
          'name': 'growth',
          'userCountThreshold': 10000,
          'categoryMultipliers': {'Coffee': 1.5},
          'saturationFactors': {
            'baseMultiplier': 1.0,
            'lowSaturationMultiplier': 0.8,
            'mediumSaturationMultiplier': 1.0,
            'highSaturationMultiplier': 1.5,
            'veryHighSaturationMultiplier': 2.0,
          },
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'metadata': {},
        };

        final phase = PlatformPhase.fromJson(json);

        expect(phase.id, equals('phase-1'));
        expect(phase.name, equals(PhaseName.growth));
        expect(phase.userCountThreshold, equals(10000));
        expect(phase.categoryMultipliers, equals({'Coffee': 1.5}));
      });
    });

    group('Phase Name Extension', () {
      test('should convert phase name to display name', () {
        expect(PhaseName.bootstrap.displayName, equals('Bootstrap'));
        expect(PhaseName.growth.displayName, equals('Growth'));
        expect(PhaseName.scale.displayName, equals('Scale'));
        expect(PhaseName.mature.displayName, equals('Mature'));
      });

      test('should parse phase name from string', () {
        expect(
          PhaseNameExtension.fromString('bootstrap'),
          equals(PhaseName.bootstrap),
        );
        expect(
          PhaseNameExtension.fromString('growth'),
          equals(PhaseName.growth),
        );
        expect(
          PhaseNameExtension.fromString('unknown'),
          equals(PhaseName.bootstrap), // Default
        );
      });
    });

    group('Saturation Factors', () {
      test('should get multiplier based on saturation ratio', () {
        final factors = SaturationFactors();

        expect(factors.getMultiplierForSaturation(0.005), equals(0.8)); // Low
        expect(factors.getMultiplierForSaturation(0.015), equals(1.0)); // Medium
        expect(factors.getMultiplierForSaturation(0.025), equals(1.5)); // High
        expect(factors.getMultiplierForSaturation(0.035), equals(2.0)); // Very high
      });

      test('should serialize saturation factors to JSON', () {
        final factors = SaturationFactors();
        final json = factors.toJson();

        expect(json['baseMultiplier'], equals(1.0));
        expect(json['lowSaturationMultiplier'], equals(0.8));
        expect(json['highSaturationMultiplier'], equals(1.5));
      });
    });
  });
}

