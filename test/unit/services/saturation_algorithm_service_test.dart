import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for SaturationAlgorithmService
void main() {
  group('SaturationAlgorithmService Tests', () {
    late SaturationAlgorithmService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = SaturationAlgorithmService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('analyzeCategorySaturation', () {
      test('should analyze low saturation category', () async {
        final metrics = await service.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 20,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 4.5,
            averageEngagementRate: 0.8,
            verifiedExpertRatio: 0.9,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 20,
            activeExperts: 18,
            totalEvents: 50,
            totalConsultations: 100,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 500,
            totalSearchQueries: 1000,
            consultationRequests: 200,
            totalUsers: 5000,
            averageWaitTimeDays: 2.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 2,
            totalExperts: 20,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 20,
            totalCities: 10,
            citiesWithExperts: 8,
          ),
        );

        expect(metrics.category, equals('Coffee'));
        expect(metrics.currentExpertCount, equals(20));
        expect(metrics.totalUserCount, equals(5000));
        expect(metrics.saturationRatio, lessThan(0.01)); // Low saturation
        expect(metrics.saturationScore, lessThan(0.3));
        expect(metrics.recommendation,
            equals(SaturationRecommendation.decrease));
      });

      test('should analyze medium saturation category', () async {
        final metrics = await service.analyzeCategorySaturation(
          category: 'Food',
          currentExpertCount: 100,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 4.2,
            averageEngagementRate: 0.7,
            verifiedExpertRatio: 0.8,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 100,
            activeExperts: 80,
            totalEvents: 200,
            totalConsultations: 500,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 300,
            totalSearchQueries: 1000,
            consultationRequests: 150,
            totalUsers: 5000,
            averageWaitTimeDays: 5.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 5,
            totalExperts: 100,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 100,
            totalCities: 10,
            citiesWithExperts: 9,
          ),
        );

        expect(metrics.saturationRatio, greaterThan(0.01));
        expect(metrics.saturationRatio, lessThan(0.02));
        expect(metrics.saturationScore, greaterThanOrEqualTo(0.3));
        expect(metrics.saturationScore, lessThan(0.5));
        expect(metrics.recommendation,
            equals(SaturationRecommendation.maintain));
      });

      test('should analyze high saturation category', () async {
        final metrics = await service.analyzeCategorySaturation(
          category: 'Travel',
          currentExpertCount: 200,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 3.8,
            averageEngagementRate: 0.5,
            verifiedExpertRatio: 0.6,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 200,
            activeExperts: 100,
            totalEvents: 150,
            totalConsultations: 300,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 100,
            totalSearchQueries: 1000,
            consultationRequests: 50,
            totalUsers: 5000,
            averageWaitTimeDays: 15.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 20,
            totalExperts: 200,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 200,
            totalCities: 10,
            citiesWithExperts: 3,
          ),
        );

        expect(metrics.saturationRatio, greaterThan(0.03));
        expect(metrics.saturationScore, greaterThan(0.7));
        expect(metrics.recommendation,
            equals(SaturationRecommendation.significantIncrease));
      });
    });

    group('getSaturationMultiplier', () {
      test('should return low multiplier for low saturation', () {
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

        final multiplier = service.getSaturationMultiplier(metrics);
        expect(multiplier, equals(0.8));
      });

      test('should return normal multiplier for medium saturation', () {
        final metrics = SaturationMetrics(
          category: 'Food',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.4,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.5,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.3,
            geographicDistribution: 0.4,
          ),
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        final multiplier = service.getSaturationMultiplier(metrics);
        expect(multiplier, equals(1.0));
      });

      test('should return high multiplier for high saturation', () {
        final metrics = SaturationMetrics(
          category: 'Travel',
          currentExpertCount: 200,
          totalUserCount: 5000,
          saturationRatio: 0.04,
          qualityScore: 0.6,
          growthRate: 20.0,
          competitionLevel: 0.8,
          marketDemand: 0.3,
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

        final multiplier = service.getSaturationMultiplier(metrics);
        expect(multiplier, equals(2.0));
      });
    });

    group('Saturation Factors Calculation', () {
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

      test('should handle edge case with zero experts', () async {
        final metrics = await service.analyzeCategorySaturation(
          category: 'NewCategory',
          currentExpertCount: 0,
          totalUserCount: 1000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 0.0,
            averageEngagementRate: 0.0,
            verifiedExpertRatio: 0.0,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 0,
            activeExperts: 0,
            totalEvents: 0,
            totalConsultations: 0,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 100,
            totalSearchQueries: 500,
            consultationRequests: 50,
            totalUsers: 1000,
            averageWaitTimeDays: 0.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 0,
            totalExperts: 0,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 0,
            totalCities: 5,
            citiesWithExperts: 0,
          ),
        );

        expect(metrics.saturationRatio, equals(0.0));
        expect(metrics.recommendation,
            equals(SaturationRecommendation.decrease));
      });
    });
  });
}

