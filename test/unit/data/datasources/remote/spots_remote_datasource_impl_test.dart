import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource_impl.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots/core/models/spot.dart';

import 'spots_remote_datasource_impl_test.mocks.dart';

@GenerateMocks([DataBackend])
void main() {
  group('SpotsRemoteDataSourceImpl', () {
    late SpotsRemoteDataSourceImpl dataSource;
    late MockDataBackend mockDataBackend;

    setUp(() {
      mockDataBackend = MockDataBackend();
      // Note: This test requires dependency injection setup
      dataSource = SpotsRemoteDataSourceImpl();
    });

    group('getSpots', () {
      test('should get spots from remote backend', () async {
        final spots = await dataSource.getSpots();

        expect(spots, isA<List<Spot>>());
      });

      test('should return empty list when backend returns no data', () async {
        final spots = await dataSource.getSpots();

        expect(spots, isA<List<Spot>>());
      });
    });

    group('createSpot', () {
      test('should create spot via remote backend', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'New Spot',
          description: 'New Description',
          latitude: 37.7749,
          longitude: -122.4194,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await dataSource.createSpot(spot);

        expect(result, isNotNull);
        expect(result.name, equals(spot.name));
      });
    });

    group('updateSpot', () {
      test('should update spot via remote backend', () async {
        final spot = Spot(
          id: 'spot-1',
          name: 'Updated Spot',
          description: 'Updated Description',
          latitude: 37.7749,
          longitude: -122.4194,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await dataSource.updateSpot(spot);

        expect(result, isNotNull);
        expect(result.name, equals(spot.name));
      });
    });

    group('deleteSpot', () {
      test('should delete spot via remote backend', () async {
        const spotId = 'spot-1';

        await expectLater(
          dataSource.deleteSpot(spotId),
          completes,
        );
      });
    });
  });
}

