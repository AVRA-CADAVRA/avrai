import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/domain/usecases/spots/update_spot_usecase.dart';
import 'package:spots/domain/repositories/spots_repository.dart';
import 'package:spots/core/models/spot.dart';

import 'update_spot_usecase_test.mocks.dart';

@GenerateMocks([SpotsRepository])
void main() {
  group('UpdateSpotUseCase', () {
    late UpdateSpotUseCase useCase;
    late MockSpotsRepository mockRepository;

    setUp(() {
      mockRepository = MockSpotsRepository();
      useCase = UpdateSpotUseCase(mockRepository);
    });

    test('should update spot via repository', () async {
      final spot = Spot(
        id: 'spot-1',
        name: 'Updated Spot',
        description: 'Updated Description',
        latitude: 37.7749,
        longitude: -122.4194,
        category: 'restaurant',
        rating: 0.0,
        createdBy: 'test-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.updateSpot(spot))
          .thenAnswer((_) async => spot);

      final result = await useCase(spot);

      expect(result, isNotNull);
      expect(result.name, equals('Updated Spot'));
      verify(mockRepository.updateSpot(spot)).called(1);
    });
  });
}

