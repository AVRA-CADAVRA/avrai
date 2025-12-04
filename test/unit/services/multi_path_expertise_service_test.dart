import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/visit.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for MultiPathExpertiseService
void main() {
  group('MultiPathExpertiseService Tests', () {
    late MultiPathExpertiseService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = MultiPathExpertiseService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('calculateExplorationExpertise', () {
      test('should calculate exploration expertise from visits', () async {
        final visits = [
          Visit(
            id: 'visit-1',
            userId: 'user-1',
            locationId: 'location-1',
            checkInTime: testDate.subtract(const Duration(days: 30)),
            checkOutTime: testDate.subtract(const Duration(days: 30)),
            dwellTime: const Duration(minutes: 30),
            qualityScore: 1.0,
            rating: 4.5,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Visit(
            id: 'visit-2',
            userId: 'user-1',
            locationId: 'location-2',
            checkInTime: testDate.subtract(const Duration(days: 20)),
            checkOutTime: testDate.subtract(const Duration(days: 20)),
            dwellTime: const Duration(minutes: 45),
            qualityScore: 1.2,
            rating: 4.8,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final expertise = await service.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: visits,
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.totalVisits, equals(2));
        expect(expertise.uniqueLocations, equals(2));
        expect(expertise.reviewsGiven, equals(2));
        expect(expertise.averageRating, greaterThan(0.0));
        expect(expertise.score, greaterThan(0.0));
        expect(expertise.score, lessThanOrEqualTo(1.0));
      });

      test('should calculate high exploration score for many visits', () async {
        final visits = List.generate(50, (i) {
          return Visit(
            id: 'visit-$i',
            userId: 'user-1',
            locationId: 'location-${i % 10}',
            checkInTime: testDate.subtract(Duration(days: 50 - i)),
            checkOutTime: testDate.subtract(Duration(days: 50 - i)),
            dwellTime: const Duration(minutes: 30),
            qualityScore: 1.0,
            rating: 4.5,
            isRepeatVisit: i > 10,
            visitNumber: i > 10 ? 2 : 1,
            createdAt: testDate,
            updatedAt: testDate,
          );
        });

        final expertise = await service.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: visits,
        );

        expect(expertise.totalVisits, equals(50));
        expect(expertise.repeatVisits, greaterThan(0));
        expect(expertise.score, greaterThan(0.7)); // High score
      });
    });

    group('calculateCredentialExpertise', () {
      test('should calculate credential expertise from degrees', () async {
        final expertise = await service.calculateCredentialExpertise(
          userId: 'user-1',
          category: 'Coffee',
          degrees: [
            EducationCredential(
              degree: 'MS',
              field: 'Food Science',
              institution: 'University',
              year: 2020,
              isVerified: true,
            ),
          ],
          certifications: [],
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.degrees.length, equals(1));
        expect(expertise.score, greaterThan(0.0));
      });

      test('should calculate credential expertise from certifications', () async {
        final expertise = await service.calculateCredentialExpertise(
          userId: 'user-1',
          category: 'Coffee',
          degrees: [],
          certifications: [
            CertificationCredential(
              name: 'Q Grader',
              issuer: 'Coffee Quality Institute',
              issuedDate: testDate.subtract(const Duration(days: 365)),
              isVerified: true,
            ),
          ],
        );

        expect(expertise.certifications.length, equals(1));
        expect(expertise.score, greaterThan(0.0));
      });
    });

    group('calculateInfluenceExpertise', () {
      test('should calculate influence expertise from followers', () async {
        final expertise = await service.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 1000,
          listSaves: 500,
          listShares: 200,
          listEngagement: 1000,
          curatedLists: 10,
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.spotsFollowers, equals(1000));
        expect(expertise.listSaves, equals(500));
        expect(expertise.score, greaterThan(0.0));
      });

      test('should calculate high influence score for many followers', () async {
        final expertise = await service.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 5000,
          listSaves: 2000,
          listShares: 1000,
          listEngagement: 5000,
          curatedLists: 20,
          popularLists: 10,
        );

        expect(expertise.score, greaterThan(0.7)); // High score
      });
    });

    group('calculateProfessionalExpertise', () {
      test('should calculate professional expertise from roles', () async {
        final expertise = await service.calculateProfessionalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          roles: [
            ProfessionalRole(
              role: 'Chef',
              title: 'Head Chef',
              employer: 'Restaurant',
              startDate: testDate.subtract(const Duration(days: 1095)),
              isCurrent: true,
              isVerified: true,
            ),
          ],
          proofOfWork: [],
          peerEndorsements: [],
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.roles.length, equals(1));
        expect(expertise.score, greaterThan(0.0));
      });
    });

    group('calculateCommunityExpertise', () {
      test('should calculate community expertise from contributions', () async {
        final expertise = await service.calculateCommunityExpertise(
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 50,
          curatedLists: 20,
          popularLists: 10,
          eventsHosted: 15,
          averageEventRating: 4.7,
          peerEndorsements: 25,
          communityContributions: 100,
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.questionsAnswered, equals(50));
        expect(expertise.eventsHosted, equals(15));
        expect(expertise.score, greaterThan(0.0));
      });
    });

    group('calculateLocalExpertise', () {
      test('should calculate local expertise from local visits', () async {
        final expertise = await service.calculateLocalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          locality: 'NYC',
          localVisits: 50,
          uniqueLocalLocations: 30,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 365),
          firstLocalVisit: testDate.subtract(const Duration(days: 365)),
          lastLocalVisit: testDate,
        );

        expect(expertise.userId, equals('user-1'));
        expect(expertise.category, equals('Coffee'));
        expect(expertise.locality, equals('NYC'));
        expect(expertise.localVisits, equals(50));
        expect(expertise.score, greaterThan(0.0));
      });

      test('should identify Golden Local Expert', () async {
        final expertise = await service.calculateLocalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          locality: 'NYC',
          localVisits: 200,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
        );

        expect(expertise.isGoldenLocalExpert, isTrue);
      });
    });
  });
}

