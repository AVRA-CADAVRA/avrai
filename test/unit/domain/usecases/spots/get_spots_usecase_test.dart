import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/domain/usecases/spots/get_spots_usecase.dart';
import 'package:spots/domain/repositories/spots_repository.dart';
import 'package:spots/core/models/spot.dart';

import 'get_spots_usecase_test.mocks.dart';

@GenerateMocks([SpotsRepository])
void main() {
  group('GetSpotsUseCase', () {
    late GetSpotsUseCase useCase;
    late MockSpotsRepository mockRepository;

    setUp(() {
      mockRepository = MockSpotsRepository();
      useCase = GetSpotsUseCase(mockRepository);
    });

    test('should get spots via repository', () async {
      final spots = [
        Spot(
          id: 'spot-1',
          name: 'Spot 1',
          description: 'Description 1',
          latitude: 37.7749,
          longitude: -122.4194,
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Spot(
          id: 'spot-2',
          name: 'Spot 2',
          description: 'Description 2',
          latitude: 37.7849,
          longitude: -122.4294,
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getSpots())
          .thenAnswer((_) async => spots);

      final result = await useCase();

      expect(result, isNotEmpty);
      expect(result.length, equals(2));
      verify(mockRepository.getSpots()).called(1);
    });

    test('should return empty list when no spots exist', () async {
      when(mockRepository.getSpots())
          .thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
      verify(mockRepository.getSpots()).called(1);
    });
  });
}

