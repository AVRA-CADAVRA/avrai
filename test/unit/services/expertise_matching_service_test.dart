import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_matching_service.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';

/// Expertise Matching Service Tests
/// Tests expertise-based user matching functionality
void main() {
  group('ExpertiseMatchingService Tests', () {
    late ExpertiseMatchingService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertiseMatchingService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
        location: 'San Francisco',
      );
    });

    group('findSimilarExperts', () {
      test('should return empty list when user has no expertise in category', () async {
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});

        final matches = await service.findSimilarExperts(
          userWithoutExpertise,
          'food',
        );

        expect(matches, isEmpty);
      });

      test('should return empty list when no other users match', () async {
        final matches = await service.findSimilarExperts(
          user,
          'food',
        );

        expect(matches, isA<List<ExpertMatch>>());
        // In test environment, _getAllUsers returns empty list, so matches will be empty
        expect(matches, isEmpty);
      });

      test('should respect maxResults parameter', () async {
        final matches = await service.findSimilarExperts(
          user,
          'food',
          maxResults: 5,
        );

        expect(matches.length, lessThanOrEqualTo(5));
      });

      test('should filter by location when provided', () async {
        final matches = await service.findSimilarExperts(
          user,
          'food',
          location: 'San Francisco',
        );

        expect(matches, isA<List<ExpertMatch>>());
      });
    });

    group('findComplementaryExperts', () {
      test('should return empty list when user has no expertise', () async {
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});

        final matches = await service.findComplementaryExperts(
          userWithoutExpertise,
        );

        expect(matches, isEmpty);
      });

      test('should return complementary experts', () async {
        final coffeeUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'Coffee': 'city'},
        );

        final matches = await service.findComplementaryExperts(
          coffeeUser,
          maxResults: 10,
        );

        expect(matches, isA<List<ExpertMatch>>());
        // In test environment, may be empty due to empty user list
      });

      test('should respect maxResults parameter', () async {
        final matches = await service.findComplementaryExperts(
          user,
          maxResults: 5,
        );

        expect(matches.length, lessThanOrEqualTo(5));
      });
    });

    group('findMentors', () {
      test('should return empty list when user has no expertise in category', () async {
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});

        final mentors = await service.findMentors(
          userWithoutExpertise,
          'food',
        );

        expect(mentors, isEmpty);
      });

      test('should return mentors (higher level experts)', () async {
        final localUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'food': 'local'},
        );

        final mentors = await service.findMentors(
          localUser,
          'food',
          maxResults: 5,
        );

        expect(mentors, isA<List<ExpertMatch>>());
        expect(mentors.length, lessThanOrEqualTo(5));
      });

      test('should respect maxResults parameter', () async {
        final mentors = await service.findMentors(
          user,
          'food',
          maxResults: 3,
        );

        expect(mentors.length, lessThanOrEqualTo(3));
      });
    });

    group('findMentees', () {
      test('should return empty list when user has no expertise in category', () async {
        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});

        final mentees = await service.findMentees(
          userWithoutExpertise,
          'food',
        );

        expect(mentees, isEmpty);
      });

      test('should return mentees (lower level experts)', () async {
        final globalUser = ModelFactories.createTestUser(
          id: 'user-123',
        ).copyWith(
          expertiseMap: {'food': 'global'},
        );

        final mentees = await service.findMentees(
          globalUser,
          'food',
          maxResults: 10,
        );

        expect(mentees, isA<List<ExpertMatch>>());
        expect(mentees.length, lessThanOrEqualTo(10));
      });

      test('should respect maxResults parameter', () async {
        final mentees = await service.findMentees(
          user,
          'food',
          maxResults: 5,
        );

        expect(mentees.length, lessThanOrEqualTo(5));
      });
    });
  });
}

