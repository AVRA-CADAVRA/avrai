import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/repositories/spots_repository_impl.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';

import 'spots_repository_impl_test.mocks.dart';

@GenerateMocks([
  SpotsLocalDataSource,
  SpotsRemoteDataSource,
  Connectivity,
])
void main() {
  late SpotsRepositoryImpl repository;
  late MockSpotsLocalDataSource mockLocal;
  late MockSpotsRemoteDataSource mockRemote;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockLocal = MockSpotsLocalDataSource();
    mockRemote = MockSpotsRemoteDataSource();
    mockConnectivity = MockConnectivity();
    repository = SpotsRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      connectivity: mockConnectivity,
    );
  });

  test('creates a spot locally and returns it when offline', () async {
    final spot = Spot(
      id: '1',
      name: 'Test Spot',
      description: 'A test spot',
      category: 'Cafe',
      latitude: 1.0,
      longitude: 2.0,
      rating: 4.5,
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(mockLocal.createSpot(spot)).thenAnswer((_) async => '1');
    when(mockLocal.getSpotById('1')).thenAnswer((_) async => spot);
    when(mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);

    final result = await repository.createSpot(spot);

    expect(result, spot);
    verify(mockLocal.createSpot(spot)).called(1);
    verify(mockLocal.getSpotById('1')).called(1);
    verifyZeroInteractions(mockRemote);
  });
}
