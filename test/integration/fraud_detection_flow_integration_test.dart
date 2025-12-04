import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/fraud_score.dart';
import 'package:spots/core/models/fraud_signal.dart';
import 'package:spots/core/models/fraud_recommendation.dart';
import '../../fixtures/model_factories.dart';

/// Integration tests for fraud detection flow
/// 
/// Tests model relationships and data flow for:
/// 1. Event creation → Fraud detection → Fraud score generation
/// 2. Fraud signals → Risk score calculation
/// 3. Risk score → Recommendation generation
void main() {
  group('Fraud Detection Flow Integration Tests', () {
    test('fraud score calculated from signals', () {
      final signals = [
        FraudSignal.newHostExpensiveEvent,
        FraudSignal.stockPhotos,
        FraudSignal.invalidLocation,
      ];

      // Calculate risk score from signal weights
      final riskScore = signals
              .map((s) => s.riskWeight)
              .reduce((a, b) => a + b)
          .clamp(0.0, 1.0);

      final recommendation = FraudRecommendation.fromRiskScore(riskScore);

      final fraudScore = FraudScore(
        id: 'fraud-123',
        eventId: 'event-456',
        riskScore: riskScore,
        signals: signals,
        recommendation: recommendation,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(fraudScore.riskScore, greaterThan(0.5));
      expect(fraudScore.signals.length, equals(3));
      expect(fraudScore.recommendation.requiresAction, isTrue);
    });

    test('fraud recommendation determined from risk score', () {
      // Low risk
      final lowRisk = FraudRecommendation.fromRiskScore(0.2);
      expect(lowRisk, equals(FraudRecommendation.approve));
      expect(lowRisk.allowsAutoApproval, isTrue);

      // Medium risk
      final mediumRisk = FraudRecommendation.fromRiskScore(0.5);
      expect(mediumRisk, equals(FraudRecommendation.review));
      expect(mediumRisk.requiresAction, isTrue);

      // High risk
      final highRisk = FraudRecommendation.fromRiskScore(0.7);
      expect(highRisk, equals(FraudRecommendation.requireVerification));
      expect(highRisk.requiresAction, isTrue);

      // Very high risk
      final veryHighRisk = FraudRecommendation.fromRiskScore(0.9);
      expect(veryHighRisk, equals(FraudRecommendation.reject));
      expect(veryHighRisk.requiresAction, isTrue);
    });

    test('fraud score risk levels', () {
      final highRiskScore = FraudScore(
        id: 'f1',
        eventId: 'e1',
        riskScore: 0.75,
        signals: const [],
        recommendation: FraudRecommendation.requireVerification,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(highRiskScore.isHighRisk, isTrue);
      expect(highRiskScore.isMediumRisk, isFalse);
      expect(highRiskScore.isLowRisk, isFalse);
      expect(highRiskScore.requiresReview, isTrue);

      final lowRiskScore = FraudScore(
        id: 'f2',
        eventId: 'e2',
        riskScore: 0.3,
        signals: const [],
        recommendation: FraudRecommendation.approve,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(lowRiskScore.isHighRisk, isFalse);
      expect(lowRiskScore.isLowRisk, isTrue);
      expect(lowRiskScore.requiresReview, isFalse);
    });

    test('admin review workflow', () {
      var fraudScore = FraudScore(
        id: 'f1',
        eventId: 'e1',
        riskScore: 0.75,
        signals: const [],
        recommendation: FraudRecommendation.review,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reviewedByAdmin: false,
      );

      expect(fraudScore.reviewedByAdmin, isFalse);

      // Admin reviews and approves
      fraudScore = fraudScore.copyWith(
        reviewedByAdmin: true,
        reviewedByAdminId: 'admin-123',
        reviewedAt: DateTime.now(),
        adminDecision: 'approved',
      );

      expect(fraudScore.reviewedByAdmin, isTrue);
      expect(fraudScore.reviewedByAdminId, equals('admin-123'));
      expect(fraudScore.adminDecision, equals('approved'));
    });

    test('multiple fraud signals increase risk', () {
      final singleSignal = [FraudSignal.stockPhotos];
      final multipleSignals = [
        FraudSignal.stockPhotos,
        FraudSignal.invalidLocation,
        FraudSignal.newHostExpensiveEvent,
        FraudSignal.suspiciouslyLowPrice,
      ];

      final singleRisk = singleSignal
          .map((s) => s.riskWeight)
          .reduce((a, b) => a + b)
          .clamp(0.0, 1.0);

      final multipleRisk = multipleSignals
          .map((s) => s.riskWeight)
          .reduce((a, b) => a + b)
          .clamp(0.0, 1.0);

      expect(multipleRisk, greaterThan(singleRisk));

      final singleScore = FraudScore(
        id: 's1',
        eventId: 'e1',
        riskScore: singleRisk,
        signals: singleSignal,
        recommendation: FraudRecommendation.fromRiskScore(singleRisk),
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final multipleScore = FraudScore(
        id: 's2',
        eventId: 'e2',
        riskScore: multipleRisk,
        signals: multipleSignals,
        recommendation: FraudRecommendation.fromRiskScore(multipleRisk),
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(multipleScore.riskScore, greaterThan(singleScore.riskScore));
      expect(multipleScore.requiresReview, isTrue);
    });
  });
}

