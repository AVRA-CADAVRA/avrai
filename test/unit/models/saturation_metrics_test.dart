import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for SaturationMetrics model
void main() {
  group('SaturationMetrics Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create saturation metrics with required fields', () {
        final factors = SaturationFactors(
          supplyRatio: 0.5,
          qualityDistribution: 0.8,
          utilizationRate: 0.7,
          demandSignal: 0.6,
          growthVelocity: 0.3,
          geographicDistribution: 0.4,
        );

        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.85,
          growthRate: 10.0,
          competitionLevel: 0.6,
          marketDemand: 0.7,
          factors: factors,
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.category, equals('Coffee'));
        expect(metrics.currentExpertCount, equals(100));
        expect(metrics.totalUserCount, equals(5000));
        expect(metrics.saturationRatio, equals(0.02));
        expect(metrics.qualityScore, equals(0.85));
        expect(metrics.saturationScore, equals(0.5));
      });
    });

    group('Saturation Multiplier', () {
      test('should return low multiplier for low saturation', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 10,
          totalUserCount: 5000,
          saturationRatio: 0.002, // 0.2%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.2,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.3,
          recommendation: SaturationRecommendation.decrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.getSaturationMultiplier(), equals(0.8));
      });

      test('should return normal multiplier for medium saturation', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 75,
          totalUserCount: 5000,
          saturationRatio: 0.015, // 1.5%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.5,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.getSaturationMultiplier(), equals(1.0));
      });

      test('should return high multiplier for high saturation', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 150,
          totalUserCount: 5000,
          saturationRatio: 0.03, // 3%
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.3,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.8,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.2,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.7,
          recommendation: SaturationRecommendation.increase,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.getSaturationMultiplier(), equals(2.0));
      });
    });

    group('Oversaturation Checks', () {
      test('should detect oversaturation', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 200,
          totalUserCount: 5000,
          saturationRatio: 0.04,
          qualityScore: 0.7,
          growthRate: 15.0,
          competitionLevel: 0.8,
          marketDemand: 0.4,
          factors: SaturationFactors(
            supplyRatio: 0.9,
            qualityDistribution: 0.6,
            utilizationRate: 0.5,
            demandSignal: 0.3,
            growthVelocity: 0.8,
            geographicDistribution: 0.7,
          ),
          saturationScore: 0.75,
          recommendation: SaturationRecommendation.significantIncrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.isOversaturated, isTrue);
      });

      test('should detect need for more experts', () {
        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 20,
          totalUserCount: 5000,
          saturationRatio: 0.004,
          qualityScore: 0.9,
          growthRate: 2.0,
          competitionLevel: 0.2,
          marketDemand: 0.8,
          factors: SaturationFactors(
            supplyRatio: 0.2,
            qualityDistribution: 0.9,
            utilizationRate: 0.9,
            demandSignal: 0.8,
            growthVelocity: 0.1,
            geographicDistribution: 0.3,
          ),
          saturationScore: 0.25,
          recommendation: SaturationRecommendation.decrease,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        expect(metrics.needsMoreExperts, isTrue);
      });
    });

    group('Saturation Factors', () {
      test('should calculate saturation score from factors', () {
        final factors = SaturationFactors(
          supplyRatio: 0.5,
          qualityDistribution: 0.8,
          utilizationRate: 0.7,
          demandSignal: 0.6,
          growthVelocity: 0.3,
          geographicDistribution: 0.4,
        );

        final score = factors.calculateSaturationScore();
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final factors = SaturationFactors(
          supplyRatio: 0.5,
          qualityDistribution: 0.8,
          utilizationRate: 0.7,
          demandSignal: 0.6,
          growthVelocity: 0.3,
          geographicDistribution: 0.4,
        );

        final metrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.85,
          growthRate: 10.0,
          competitionLevel: 0.6,
          marketDemand: 0.7,
          factors: factors,
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        final json = metrics.toJson();

        expect(json['category'], equals('Coffee'));
        expect(json['currentExpertCount'], equals(100));
        expect(json['saturationRatio'], equals(0.02));
        expect(json['recommendation'], equals('maintain'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'category': 'Coffee',
          'currentExpertCount': 100,
          'totalUserCount': 5000,
          'saturationRatio': 0.02,
          'qualityScore': 0.85,
          'growthRate': 10.0,
          'competitionLevel': 0.6,
          'marketDemand': 0.7,
          'factors': {
            'supplyRatio': 0.5,
            'qualityDistribution': 0.8,
            'utilizationRate': 0.7,
            'demandSignal': 0.6,
            'growthVelocity': 0.3,
            'geographicDistribution': 0.4,
          },
          'saturationScore': 0.5,
          'recommendation': 'maintain',
          'calculatedAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'metadata': {},
        };

        final metrics = SaturationMetrics.fromJson(json);

        expect(metrics.category, equals('Coffee'));
        expect(metrics.currentExpertCount, equals(100));
        expect(metrics.saturationRatio, equals(0.02));
        expect(metrics.recommendation, equals(SaturationRecommendation.maintain));
      });
    });

    group('Saturation Recommendation Extension', () {
      test('should convert recommendation to display name', () {
        expect(
          SaturationRecommendation.decrease.displayName,
          equals('Decrease Requirements'),
        );
        expect(
          SaturationRecommendation.maintain.displayName,
          equals('Maintain Requirements'),
        );
        expect(
          SaturationRecommendation.increase.displayName,
          equals('Increase Requirements'),
        );
      });

      test('should parse recommendation from string', () {
        expect(
          SaturationRecommendationExtension.fromString('decrease'),
          equals(SaturationRecommendation.decrease),
        );
        expect(
          SaturationRecommendationExtension.fromString('maintain'),
          equals(SaturationRecommendation.maintain),
        );
        expect(
          SaturationRecommendationExtension.fromString('unknown'),
          equals(SaturationRecommendation.maintain), // Default
        );
      });
    });
  });
}

