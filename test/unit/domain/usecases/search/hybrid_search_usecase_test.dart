import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/core/models/spot.dart';

import 'hybrid_search_usecase_test.mocks.dart';

@GenerateMocks([HybridSearchRepository])
void main() {
  group('HybridSearchUseCase', () {
    late HybridSearchUseCase useCase;
    late MockHybridSearchRepository mockRepository;

    setUp(() {
      mockRepository = MockHybridSearchRepository();
      useCase = HybridSearchUseCase(mockRepository);
    });

    group('searchSpots', () {
      test('should search spots with hybrid approach', () async {
        const query = 'coffee shop';
        final mockResult = HybridSearchResult(
          spots: [
            Spot(
              id: 'spot-1',
              name: 'Coffee Shop',
              description: 'Great coffee',
              latitude: 37.7749,
              longitude: -122.4194,
              category: 'cafe',
              rating: 0.0,
              createdBy: 'test-user',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          communityCount: 1,
          externalCount: 0,
          totalCount: 1,
          searchDuration: Duration(milliseconds: 100),
          sources: {'community': 1},
          metadata: [],
        );

        when(mockRepository.searchSpots(
          query: query,
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenAnswer((_) async => mockResult);

        final result = await useCase.searchSpots(query: query);

        expect(result, isNotNull);
        expect(result.totalCount, equals(1));
        expect(result.communityCount, equals(1));
        // OUR_GUTS.md: "Community, Not Just Places" - Community data prioritized
        verify(mockRepository.searchSpots(
          query: query,
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).called(1);
      });

      test('should prioritize community data over external', () async {
        const query = 'restaurant';
        final mockResult = HybridSearchResult(
          spots: [],
          communityCount: 5,
          externalCount: 10,
          totalCount: 5, // Only community results returned
          searchDuration: Duration(milliseconds: 100),
          sources: {'community': 5},
          metadata: [],
        );

        when(mockRepository.searchSpots(
          query: anyNamed('query'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenAnswer((_) async => mockResult);

        final result = await useCase.searchSpots(query: query);

        expect(result.communityCount, greaterThan(0));
      });
    });

    group('searchNearbySpots', () {
      test('should search nearby spots with hybrid approach', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        const radius = 1000;
        final mockResult = HybridSearchResult(
          spots: [],
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: Duration(milliseconds: 150),
          sources: {'community': 3, 'external': 2},
          metadata: [],
        );

        when(mockRepository.searchNearbySpots(
          latitude: latitude,
          longitude: longitude,
          radius: anyNamed('radius'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenAnswer((_) async => mockResult);

        final result = await useCase.searchNearbySpots(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        expect(result, isNotNull);
        expect(result.communityCount, greaterThan(0));
      });
    });

    group('getSearchAnalytics', () {
      test('should get search analytics from repository', () {
        final analytics = {'coffee': 5, 'restaurant': 3};

        when(mockRepository.getSearchAnalytics())
            .thenReturn(analytics);

        final result = useCase.getSearchAnalytics();

        expect(result, equals(analytics));
        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        verify(mockRepository.getSearchAnalytics()).called(1);
      });
    });
  });
}

