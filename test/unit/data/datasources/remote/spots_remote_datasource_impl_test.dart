import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource_impl.dart';
import 'package:spots_network/spots_network.dart';
import 'package:spots_core/spots_core.dart' as spots_core;
import 'package:spots/core/models/spot.dart';
import 'package:spots/injection_container.dart' as di;

import 'spots_remote_datasource_impl_test.mocks.dart';

@GenerateMocks([DataBackend])
void main() {
  group('SpotsRemoteDataSourceImpl', () {
    late SpotsRemoteDataSourceImpl dataSource;
    late MockDataBackend mockDataBackend;

    setUp(() async {
      mockDataBackend = MockDataBackend();
      await di.sl.reset();
      di.sl.registerSingleton<DataBackend>(mockDataBackend);
      dataSource = SpotsRemoteDataSourceImpl();
    });
    
    tearDown(() async {
      await di.sl.reset();
    });

    group('getSpots', () {
      test('should get spots from remote backend', () async {
        final coreSpots = <spots_core.Spot>[
          spots_core.Spot(
            id: 'spot-1',
            name: 'Spot 1',
            description: 'Desc',
            latitude: 37.7749,
            longitude: -122.4194,
            category: 'restaurant',
            rating: 4.2,
            createdBy: 'test-user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        when(mockDataBackend.getSpots(limit: anyNamed('limit')))
            .thenAnswer((_) async => ApiResponse.success(coreSpots));

        final spots = await dataSource.getSpots();

        expect(spots, isA<List<Spot>>());
        expect(spots.length, equals(1));
      });

      test('should return empty list when backend returns no data', () async {
        when(mockDataBackend.getSpots(limit: anyNamed('limit')))
            .thenAnswer((_) async => ApiResponse.success(<spots_core.Spot>[]));
        final spots = await dataSource.getSpots();

        expect(spots, isA<List<Spot>>());
        expect(spots, isEmpty);
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
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDataBackend.createSpot(any)).thenAnswer(
          (_) async => ApiResponse.success(
            spots_core.Spot.fromJson(spot.toJson()),
          ),
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
          category: 'restaurant',
          rating: 0.0,
          createdBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockDataBackend.updateSpot(any)).thenAnswer(
          (_) async => ApiResponse.success(
            spots_core.Spot.fromJson(spot.toJson()),
          ),
        );
        final result = await dataSource.updateSpot(spot);

        expect(result, isNotNull);
        expect(result.name, equals(spot.name));
      });
    });

    group('deleteSpot', () {
      test('should delete spot via remote backend', () async {
        const spotId = 'spot-1';

        when(mockDataBackend.deleteSpot(spotId))
            .thenAnswer((_) async => const ApiResponse<void>(success: true));
        await expectLater(
          dataSource.deleteSpot(spotId),
          completes,
        );
        verify(mockDataBackend.deleteSpot(spotId)).called(1);
      });
    });
  });
}

