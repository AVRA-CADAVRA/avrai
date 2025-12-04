import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/local_expert_qualification.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LocalExpertQualification model
void main() {
  group('LocalExpertQualification Model Tests', () {
    late DateTime testDate;
    late ThresholdValues baseThresholds;
    late ThresholdValues localityThresholds;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();

      baseThresholds = const ThresholdValues(
        minVisits: 10,
        minRatings: 5,
        minAvgRating: 4.0,
        minTimeInCategory: Duration(days: 30),
        minCommunityEngagement: 3,
        minListCuration: 2,
        minEventHosting: 1,
      );

      localityThresholds = const ThresholdValues(
        minVisits: 7, // Lower (30% reduction)
        minRatings: 4, // Lower
        minAvgRating: 4.0, // Same
        minTimeInCategory: Duration(days: 30), // Same
        minCommunityEngagement: 2, // Lower
        minListCuration: 1, // Lower
        minEventHosting: 1, // Same
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create qualification with required fields', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 5,
            ratings: 3,
            avgRating: 4.5,
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(qualification.id, equals('qual-123'));
        expect(qualification.userId, equals('user-123'));
        expect(qualification.category, equals('Coffee'));
        expect(qualification.locality, equals('Greenpoint'));
        expect(qualification.currentLevel, equals(ExpertiseLevel.local));
        expect(qualification.isQualified, isFalse);
      });
    });

    group('Progress Percentage', () {
      test('should calculate progress percentage correctly', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7, // Met
            ratings: 4, // Met
            avgRating: 4.5, // Met (>= 4.0)
            communityEngagement: 2, // Met
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // All thresholds met = 100% progress
        expect(qualification.progressPercentage, equals(1.0));
      });

      test('should calculate partial progress', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7, // Met
            ratings: 2, // Not met (needs 4)
            avgRating: 4.5, // Met
            communityEngagement: 1, // Not met (needs 2)
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // 4 out of 6 thresholds met = ~67%
        expect(qualification.progressPercentage, closeTo(0.67, 0.01));
      });

      test('should return 1.0 if already qualified', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          isQualified: true,
          qualifiedAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(qualification.progressPercentage, equals(1.0));
      });
    });

    group('Remaining Requirements', () {
      test('should calculate remaining requirements', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 5, // Needs 2 more (7 - 5)
            ratings: 2, // Needs 2 more (4 - 2)
            avgRating: 4.5, // Met
            communityEngagement: 1, // Needs 1 more (2 - 1)
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final remaining = qualification.remainingRequirements;
        expect(remaining['visits'], equals(2));
        expect(remaining['ratings'], equals(2));
        expect(remaining['communityEngagement'], equals(1));
        expect(remaining.containsKey('listCuration'), isFalse);
        expect(remaining.containsKey('eventHosting'), isFalse);
      });

      test('should return empty map if all requirements met', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 7,
            ratings: 4,
            avgRating: 4.5,
            communityEngagement: 2,
            listCuration: 1,
            eventHosting: 1,
          ),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(qualification.remainingRequirements, isEmpty);
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final qualification = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(
            visits: 5,
            ratings: 3,
          ),
          factors: const QualificationFactors(
            listsWithFollowers: 2,
            hasProfessionalBackground: true,
          ),
          isQualified: false,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = qualification.toJson();

        expect(json['id'], equals('qual-123'));
        expect(json['userId'], equals('user-123'));
        expect(json['category'], equals('Coffee'));
        expect(json['locality'], equals('Greenpoint'));
        expect(json['currentLevel'], equals('local'));
        expect(json['isQualified'], isFalse);
        expect(json['qualifiedAt'], isNull);
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'qual-123',
          'userId': 'user-123',
          'category': 'Coffee',
          'locality': 'Greenpoint',
          'currentLevel': 'local',
          'baseThresholds': baseThresholds.toJson(),
          'localityThresholds': localityThresholds.toJson(),
          'progress': const QualificationProgress(visits: 5).toJson(),
          'factors': const QualificationFactors().toJson(),
          'isQualified': false,
          'qualifiedAt': null,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final qualification = LocalExpertQualification.fromJson(json);

        expect(qualification.id, equals('qual-123'));
        expect(qualification.userId, equals('user-123'));
        expect(qualification.category, equals('Coffee'));
        expect(qualification.locality, equals('Greenpoint'));
        expect(qualification.currentLevel, equals(ExpertiseLevel.local));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          isQualified: true,
          qualifiedAt: testDate,
          currentLevel: ExpertiseLevel.city,
        );

        expect(updated.id, equals('qual-123'));
        expect(updated.isQualified, isTrue);
        expect(updated.qualifiedAt, equals(testDate));
        expect(updated.currentLevel, equals(ExpertiseLevel.city));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final qual1 = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final qual2 = LocalExpertQualification(
          id: 'qual-123',
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          currentLevel: ExpertiseLevel.local,
          baseThresholds: baseThresholds,
          localityThresholds: localityThresholds,
          progress: const QualificationProgress(),
          factors: const QualificationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(qual1, equals(qual2));
      });
    });
  });
}

