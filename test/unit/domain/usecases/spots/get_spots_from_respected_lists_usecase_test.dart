import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:spots/domain/repositories/spots_repository.dart';
import 'package:spots/core/models/spot.dart';

import 'get_spots_from_respected_lists_usecase_test.mocks.dart';

@GenerateMocks([SpotsRepository])
void main() {
  group('GetSpotsFromRespectedListsUseCase', () {
    late GetSpotsFromRespectedListsUseCase useCase;
    late MockSpotsRepository mockRepository;

    setUp(() {
      mockRepository = MockSpotsRepository();
      useCase = GetSpotsFromRespectedListsUseCase(mockRepository);
    });

    test('should get spots from respected lists via repository', () async {
      final spots = [
        Spot(
          id: 'spot-1',
          name: 'Respected Spot',
          description: 'From respected list',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getSpotsFromRespectedLists())
          .thenAnswer((_) async => spots);

      final result = await useCase();

      expect(result, isNotEmpty);
      verify(mockRepository.getSpotsFromRespectedLists()).called(1);
    });

    test('should return empty list when no respected spots exist', () async {
      when(mockRepository.getSpotsFromRespectedLists())
          .thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
      verify(mockRepository.getSpotsFromRespectedLists()).called(1);
    });
  });
}

