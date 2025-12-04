import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/repositories/spots_repository_impl.dart';
import 'package:spots/core/models/spot.dart';

import '../../fixtures/model_factories.dart';
import '../../mocks/mock_dependencies.mocks.dart';

/// Comprehensive test suite for SpotsRepositoryImpl
/// Tests the current implementation behavior without modifying production code
/// 
/// Focus Areas:
/// - CRUD operations with offline-first strategy
/// - Connectivity handling and fallback mechanisms  
/// - Error scenarios and recovery
/// - Data synchronization between local and remote
void main() {
  group('SpotsRepositoryImpl Tests', () {
    late SpotsRepositoryImpl repository;
    late MockSpotsLocalDataSource mockLocalDataSource;
    late MockSpotsRemoteDataSource mockRemoteDataSource;
    late MockConnectivity mockConnectivity;
    
    late Spot testSpot;
    late List<Spot> testSpots;

    setUp(() {
      mockLocalDataSource = MockSpotsLocalDataSource();
      mockRemoteDataSource = MockSpotsRemoteDataSource();
      mockConnectivity = MockConnectivity();
      
      repository = SpotsRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        connectivity: mockConnectivity,
      );
      
      testSpot = ModelFactories.createTestSpot();
      testSpots = ModelFactories.createTestSpots(3);
    });

    tearDown(() {
      reset(mockLocalDataSource);
      reset(mockRemoteDataSource);
      reset(mockConnectivity);
    });

    group('getSpots', () {
      test('returns local spots when offline', () async {
        // Arrange: Configure offline scenario
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => testSpots);

        // Act
        final result = await repository.getSpots();

        // Assert
        expect(result, equals(testSpots));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.getAllSpots()).called(1);
        verifyNever(mockRemoteDataSource.getSpots());
      });

      test('returns local spots when online but remote sync disabled', () async {
        // Arrange: Configure online scenario
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => testSpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => ModelFactories.createTestSpots(5));

        // Act
        final result = await repository.getSpots();

        // Assert: Current implementation returns local data even when online
        expect(result, equals(testSpots));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.getAllSpots()).called(1);
        verify(mockRemoteDataSource.getSpots()).called(1);
      });

      test('falls back to local when remote fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => testSpots);
        when(mockRemoteDataSource.getSpots())
            .thenThrow(Exception('Remote server error'));

        // Act
        final result = await repository.getSpots();

        // Assert
        expect(result, equals(testSpots));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.getAllSpots()).called(1);
        verify(mockRemoteDataSource.getSpots()).called(1);
      });

      test('throws exception when local data source fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getAllSpots())
            .thenThrow(Exception('Local database error'));

        // Act & Assert
        expect(
          () => repository.getSpots(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get spots'),
          )),
        );
      });
    });

    group('getSpotsFromRespectedLists', () {
      test('returns respected spots from local source', () async {
        // Arrange
        final respectedSpots = ModelFactories.createTestSpots(2);
        when(mockLocalDataSource.getSpotsFromRespectedLists())
            .thenAnswer((_) async => respectedSpots);

        // Act
        final result = await repository.getSpotsFromRespectedLists();

        // Assert
        expect(result, equals(respectedSpots));
        verify(mockLocalDataSource.getSpotsFromRespectedLists()).called(1);
      });

      test('throws exception when local source fails', () async {
        // Arrange
        when(mockLocalDataSource.getSpotsFromRespectedLists())
            .thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(
          () => repository.getSpotsFromRespectedLists(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get spots from respected lists'),
          )),
        );
      });
    });

    group('createSpot', () {
      test('creates spot locally when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.createSpot(testSpot))
            .thenAnswer((_) async => testSpot.id);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);

        // Act
        final result = await repository.createSpot(testSpot);

        // Assert
        expect(result, equals(testSpot));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.createSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verifyNever(mockRemoteDataSource.createSpot(any));
      });

      test('syncs to remote when online and updates local with remote data', () async {
        // Arrange
        final remoteSpot = ModelFactories.createTestSpot(id: 'remote-spot-id');
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.createSpot(testSpot))
            .thenAnswer((_) async => testSpot.id);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);
        when(mockRemoteDataSource.createSpot(testSpot))
            .thenAnswer((_) async => remoteSpot);
        when(mockLocalDataSource.updateSpot(remoteSpot))
            .thenAnswer((_) async => remoteSpot);

        // Act
        final result = await repository.createSpot(testSpot);

        // Assert
        expect(result, equals(remoteSpot));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.createSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verify(mockRemoteDataSource.createSpot(testSpot)).called(1);
        verify(mockLocalDataSource.updateSpot(remoteSpot)).called(1);
      });

      test('falls back to local when remote sync fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.createSpot(testSpot))
            .thenAnswer((_) async => testSpot.id);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);
        when(mockRemoteDataSource.createSpot(testSpot))
            .thenThrow(Exception('Remote creation failed'));

        // Act
        final result = await repository.createSpot(testSpot);

        // Assert
        expect(result, equals(testSpot));
        verify(mockLocalDataSource.createSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verify(mockRemoteDataSource.createSpot(testSpot)).called(1);
      });

      test('throws exception when local creation fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.createSpot(testSpot))
            .thenThrow(Exception('Local storage full'));

        // Act & Assert
        expect(
          () => repository.createSpot(testSpot),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to create spot'),
          )),
        );
      });

      test('throws exception when locally created spot cannot be retrieved', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.createSpot(testSpot))
            .thenAnswer((_) async => testSpot.id);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.createSpot(testSpot),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to create spot locally'),
          )),
        );
      });
    });

    group('updateSpot', () {
      test('updates spot locally when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.updateSpot(testSpot))
            .thenAnswer((_) async => testSpot);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);

        // Act
        final result = await repository.updateSpot(testSpot);

        // Assert
        expect(result, equals(testSpot));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.updateSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verifyNever(mockRemoteDataSource.updateSpot(any));
      });

      test('syncs to remote when online and updates local with remote data', () async {
        // Arrange
        final remoteSpot = ModelFactories.createTestSpot(
          id: testSpot.id,
          name: 'Updated Remote Spot',
        );
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.updateSpot(testSpot))
            .thenAnswer((_) async => testSpot);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);
        when(mockRemoteDataSource.updateSpot(testSpot))
            .thenAnswer((_) async => remoteSpot);
        when(mockLocalDataSource.updateSpot(remoteSpot))
            .thenAnswer((_) async => remoteSpot);

        // Act
        final result = await repository.updateSpot(testSpot);

        // Assert
        expect(result, equals(remoteSpot));
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.updateSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verify(mockRemoteDataSource.updateSpot(testSpot)).called(1);
        verify(mockLocalDataSource.updateSpot(remoteSpot)).called(1);
      });

      test('falls back to local when remote update fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.updateSpot(testSpot))
            .thenAnswer((_) async => testSpot);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => testSpot);
        when(mockRemoteDataSource.updateSpot(testSpot))
            .thenThrow(Exception('Remote update failed'));

        // Act
        final result = await repository.updateSpot(testSpot);

        // Assert
        expect(result, equals(testSpot));
        verify(mockLocalDataSource.updateSpot(testSpot)).called(1);
        verify(mockLocalDataSource.getSpotById(testSpot.id)).called(1);
        verify(mockRemoteDataSource.updateSpot(testSpot)).called(1);
      });

      test('throws exception when updated spot cannot be retrieved locally', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.updateSpot(testSpot))
            .thenAnswer((_) async => testSpot);
        when(mockLocalDataSource.getSpotById(testSpot.id))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.updateSpot(testSpot),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to update spot locally'),
          )),
        );
      });
    });

    group('deleteSpot', () {
      test('deletes spot locally when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.deleteSpot(testSpot.id))
            .thenAnswer((_) async {});

        // Act
        await repository.deleteSpot(testSpot.id);

        // Assert
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.deleteSpot(testSpot.id)).called(1);
        verifyNever(mockRemoteDataSource.deleteSpot(any));
      });

      test('deletes from both local and remote when online', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.deleteSpot(testSpot.id))
            .thenAnswer((_) async {});
        when(mockRemoteDataSource.deleteSpot(testSpot.id))
            .thenAnswer((_) async {});

        // Act
        await repository.deleteSpot(testSpot.id);

        // Assert
        verify(mockConnectivity.checkConnectivity()).called(1);
        verify(mockLocalDataSource.deleteSpot(testSpot.id)).called(1);
        verify(mockRemoteDataSource.deleteSpot(testSpot.id)).called(1);
      });

      test('continues when remote delete fails but local succeeds', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.deleteSpot(testSpot.id))
            .thenAnswer((_) async {});
        when(mockRemoteDataSource.deleteSpot(testSpot.id))
            .thenThrow(Exception('Remote delete failed'));

        // Act
        await repository.deleteSpot(testSpot.id);

        // Assert
        verify(mockLocalDataSource.deleteSpot(testSpot.id)).called(1);
        verify(mockRemoteDataSource.deleteSpot(testSpot.id)).called(1);
      });

      test('throws exception when local delete fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.deleteSpot(testSpot.id))
            .thenThrow(Exception('Local delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteSpot(testSpot.id),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to delete spot'),
          )),
        );
      });
    });

    group('Edge Cases and Performance', () {
      test('handles connectivity check failure gracefully', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity service unavailable'));
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => testSpots);

        // Act: Should still function with local data when connectivity check fails
        final result = await repository.getSpots();

        // Assert: Should return local spots
        expect(result, equals(testSpots));
        verify(mockLocalDataSource.getAllSpots()).called(1);
      });

      test('handles multiple rapid requests correctly', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => testSpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testSpots);

        // Act: Make multiple concurrent requests
        final futures = List.generate(
          5,
          (_) => repository.getSpots(),
        );
        final results = await Future.wait(futures);

        // Assert: All requests should complete successfully
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result, equals(testSpots));
        }
      });

      test('handles large datasets efficiently', () async {
        // Arrange
        final largeSpotsList = ModelFactories.createTestSpots(1000);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockLocalDataSource.getAllSpots())
            .thenAnswer((_) async => largeSpotsList);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await repository.getSpots();
        stopwatch.stop();

        // Assert: Should handle large datasets reasonably quickly
        expect(result.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}