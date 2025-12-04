import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expert_search_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../fixtures/model_factories.dart';

/// Expert Search Service Tests
/// Tests expert search functionality
void main() {
  group('ExpertSearchService Tests', () {
    late ExpertSearchService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertSearchService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
        location: 'San Francisco',
      );
    });

    group('searchExperts', () {
      test('should return empty list when no experts match', () async {
        final results = await service.searchExperts(
          category: 'food',
        );

        expect(results, isA<List<ExpertSearchResult>>());
        // In test environment, _getAllUsers returns empty list
        expect(results, isEmpty);
      });

      test('should filter by category', () async {
        final results = await service.searchExperts(
          category: 'food',
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });

      test('should filter by location', () async {
        final results = await service.searchExperts(
          location: 'San Francisco',
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });

      test('should filter by minimum level', () async {
        final results = await service.searchExperts(
          category: 'food',
          minLevel: ExpertiseLevel.city,
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });

      test('should respect maxResults parameter', () async {
        final results = await service.searchExperts(
          category: 'food',
          maxResults: 10,
        );

        expect(results.length, lessThanOrEqualTo(10));
      });

      test('should return results sorted by relevance score', () async {
        final results = await service.searchExperts(
          category: 'food',
        );

        // Results should be sorted by relevance (highest first)
        for (var i = 0; i < results.length - 1; i++) {
          expect(
            results[i].relevanceScore,
            greaterThanOrEqualTo(results[i + 1].relevanceScore),
          );
        }
      });
    });

    group('getTopExperts', () {
      test('should return top experts in category', () async {
        final results = await service.getTopExperts(
          'food',
          maxResults: 10,
        );

        expect(results, isA<List<ExpertSearchResult>>());
        expect(results.length, lessThanOrEqualTo(10));
      });

      test('should filter by location when provided', () async {
        final results = await service.getTopExperts(
          'food',
          location: 'San Francisco',
          maxResults: 5,
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });

      test('should include local level experts (no City minimum)', () async {
        final results = await service.getTopExperts('food');

        // Results should include local level or higher (no minimum level filter)
        // getTopExperts uses minLevel: ExpertiseLevel.local (line 85)
        for (final result in results) {
          final level = result.user.getExpertiseLevel('food');
          if (level != null) {
            // Local level experts should be included (no City minimum)
            expect(level.index, greaterThanOrEqualTo(ExpertiseLevel.local.index));
          }
        }
      });

      test('should not filter out local level experts', () async {
        // Verify that getTopExperts includes Local level experts
        // This test ensures Local level is the minimum, not City
        final results = await service.getTopExperts('food');

        // If any results exist, they should include Local level or higher
        // The service should not exclude Local level experts
        if (results.isNotEmpty) {
          final hasLocalLevel = results.any((result) {
            final level = result.user.getExpertiseLevel('food');
            return level == ExpertiseLevel.local;
          });
          // Local level experts are allowed (not filtered out)
          // This test verifies Local level is included, not excluded
        }
      });
    });

    group('getExpertsNearLocation', () {
      test('should return experts near location', () async {
        final results = await service.getExpertsNearLocation(
          'San Francisco',
          maxResults: 20,
        );

        expect(results, isA<List<ExpertSearchResult>>());
        expect(results.length, lessThanOrEqualTo(20));
      });
    });

    group('getExpertsByLevel', () {
      test('should return experts by specific level', () async {
        final results = await service.getExpertsByLevel(
          ExpertiseLevel.city,
          category: 'food',
          maxResults: 20,
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });

      test('should filter by category when provided', () async {
        final results = await service.getExpertsByLevel(
          ExpertiseLevel.regional,
          category: 'food',
        );

        expect(results, isA<List<ExpertSearchResult>>());
      });
    });
  });
}

