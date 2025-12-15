import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/domain/usecases/spots/create_spot_usecase.dart';
import 'package:spots/domain/repositories/spots_repository.dart';
import 'package:spots/core/models/spot.dart';

import 'create_spot_usecase_test.mocks.dart';

@GenerateMocks([SpotsRepository])
void main() {
  group('CreateSpotUseCase', () {
    late CreateSpotUseCase useCase;
    late MockSpotsRepository mockRepository;

    setUp(() {
      mockRepository = MockSpotsRepository();
      useCase = CreateSpotUseCase(mockRepository);
    });

    test('should create spot via repository', () async {
      final spot = Spot(
        id: 'spot-1',
        name: 'New Spot',
        description: 'New Description',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'restaurant',
        rating: 0.0,
        createdBy: 'test-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createSpot(spot))
          .thenAnswer((_) async => spot);

      final result = await useCase(spot);

      expect(result, isNotNull);
      expect(result.name, equals('New Spot'));
      verify(mockRepository.createSpot(spot)).called(1);
    });
  });
}

