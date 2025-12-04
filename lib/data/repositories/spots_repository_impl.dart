import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/domain/repositories/spots_repository.dart';

class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsRemoteDataSource remoteDataSource;
  final SpotsLocalDataSource localDataSource;
  final Connectivity connectivity;

  SpotsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivity,
  });

  @override
  Future<List<Spot>> getSpots() async {
    try {
      // Always try to get from local first
      final localSpots = await localDataSource.getAllSpots();

      // Check connectivity (robust to plugin return types)
      final offline = await _isOffline();
      if (offline) {
        return localSpots;
      }

      // If online, try to sync with remote
      try {
        final remoteSpots = await remoteDataSource.getSpots();
        // For now, just return local data since remote is stubbed
        return localSpots;
      } catch (e) {
        // If remote fails, return local data
        return localSpots;
      }
    } catch (e) {
      throw Exception('Failed to get spots: $e');
    }
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    try {
      // Get spots from respected lists
      final respectedSpots = await localDataSource.getSpotsFromRespectedLists();
      return respectedSpots;
    } catch (e) {
      throw Exception('Failed to get spots from respected lists: $e');
    }
  }

  /// Convenience method used in performance tests
  Future<Spot?> getSpotById(String id) async {
    try {
      return await localDataSource.getSpotById(id);
    } catch (e) {
      throw Exception('Failed to get spot by id: $e');
    }
  }

  @override
  Future<Spot> createSpot(Spot spot) async {
    try {
      // Always save locally first
      final spotId = await localDataSource.createSpot(spot);
      final createdSpot = await localDataSource.getSpotById(spotId);

      if (createdSpot == null) {
        throw Exception('Failed to create spot locally');
      }

      // Check connectivity (robust to plugin return types)
      final offline = await _isOffline();
      if (offline) {
        return createdSpot;
      }

      // If online, try to sync with remote
      try {
        final remoteSpot = await remoteDataSource.createSpot(spot);
        // Update local with remote data
        await localDataSource.updateSpot(remoteSpot);
        return remoteSpot;
      } catch (e) {
        // If remote fails, return local data
        return createdSpot;
      }
    } catch (e) {
      throw Exception('Failed to create spot: $e');
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    try {
      // Always update locally first
      await localDataSource.updateSpot(spot);
      final updatedSpot = await localDataSource.getSpotById(spot.id);

      if (updatedSpot == null) {
        throw Exception('Failed to update spot locally');
      }

      // Check connectivity (robust to plugin return types)
      final offline = await _isOffline();
      if (offline) {
        return updatedSpot;
      }

      // If online, try to sync with remote
      try {
        final remoteSpot = await remoteDataSource.updateSpot(spot);
        // Update local with remote data
        await localDataSource.updateSpot(remoteSpot);
        return remoteSpot;
      } catch (e) {
        // If remote fails, return local data
        return updatedSpot;
      }
    } catch (e) {
      throw Exception('Failed to update spot: $e');
    }
  }

  @override
  Future<void> deleteSpot(String spotId) async {
    try {
      // Always delete locally first
      await localDataSource.deleteSpot(spotId);

      // Check connectivity (robust to plugin return types)
      final offline = await _isOffline();
      if (offline) {
        return;
      }

      // If online, try to sync with remote
      try {
        await remoteDataSource.deleteSpot(spotId);
      } catch (e) {
        // If remote fails, local deletion is already done
      }
    } catch (e) {
      throw Exception('Failed to delete spot: $e');
    }
  }

  Future<bool> _isOffline() async {
    try {
      final result = await connectivity.checkConnectivity();
      // Handle both ConnectivityResult and List<ConnectivityResult>
      if (result is ConnectivityResult) {
        return result == ConnectivityResult.none;
      }
      return result.contains(ConnectivityResult.none);
          return false;
    } catch (_) {
      // On failure, assume offline to be safe
      return true;
    }
  }
}
