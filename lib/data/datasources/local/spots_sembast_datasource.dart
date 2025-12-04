import 'package:spots/core/services/logger.dart';
import 'package:sembast/sembast.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';

class SpotsSembastDataSource implements SpotsLocalDataSource {
  final StoreRef<String, Map<String, dynamic>> _store;
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  SpotsSembastDataSource() : _store = SembastDatabase.spotsStore;

  @override
  Future<Spot?> getSpotById(String id) async {
    try {
      final db = await SembastDatabase.database;
      final record = await _store.record(id).get(db);
      if (record != null) {
        return Spot.fromJson(record);
      }
      return null;
    } catch (e) {
      _logger.error('Error getting spot', error: e, tag: 'SpotsSembastDataSource');
      return null;
    }
  }

  @override
  Future<String> createSpot(Spot spot) async {
    try {
      final db = await SembastDatabase.database;
      final spotData = spot.toJson();
      final key = await _store.add(db, spotData);
      return key;
    } catch (e) {
      _logger.error('Error creating spot', error: e, tag: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<Spot> updateSpot(Spot spot) async {
    try {
      final db = await SembastDatabase.database;
      final spotData = spot.toJson();
      await _store.record(spot.id).put(db, spotData);
      return spot;
    } catch (e) {
      _logger.error('Error updating spot', error: e, tag: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<void> deleteSpot(String id) async {
    try {
      final db = await SembastDatabase.database;
      await _store.record(id).delete(db);
    } catch (e) {
      _logger.error('Error deleting spot', error: e, tag: 'SpotsSembastDataSource');
      rethrow;
    }
  }

  @override
  Future<List<Spot>> getSpotsByCategory(String category) async {
    try {
      final db = await SembastDatabase.database;
      final finder = Finder(filter: Filter.equals('category', category));
      final records = await _store.find(db, finder: finder);
      return records.map((record) => Spot.fromJson(record.value)).toList();
    } catch (e) {
      _logger.error('Error getting spots by category', error: e, tag: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> getAllSpots() async {
    try {
      final db = await SembastDatabase.database;
      final records = await _store.find(db);
      return records.map((record) {
        final data = record.value;
        final now = DateTime.now();
        return Spot(
          id: record.key,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          latitude: data['latitude']?.toDouble() ?? 0.0,
          longitude: data['longitude']?.toDouble() ?? 0.0,
          category: data['category'] ?? '',
          rating: data['rating']?.toDouble() ?? 0.0,
          createdBy: data['createdBy'] ?? '',
          createdAt: DateTime.parse(data['createdAt'] ?? now.toIso8601String()),
          updatedAt: DateTime.parse(data['updatedAt'] ?? now.toIso8601String()),
        );
      }).toList();
    } catch (e) {
      _logger.error('Error getting all spots', error: e, tag: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> getSpotsFromRespectedLists() async {
    try {
      // Implementation for getting spots from respected lists
      return [];
    } catch (e) {
      _logger.error('Error getting spots from respected lists', error: e, tag: 'SpotsSembastDataSource');
      return [];
    }
  }

  @override
  Future<List<Spot>> searchSpots(String query) async {
    try {
      final db = await SembastDatabase.database;
      final records = await _store.find(db);
      final queryLower = query.toLowerCase();
      
      return records.where((record) {
        final data = record.value;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final description = (data['description'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();
        
        return name.contains(queryLower) || 
               description.contains(queryLower) || 
               category.contains(queryLower);
      }).map((record) {
        final data = record.value;
        final now = DateTime.now();
        return Spot(
          id: record.key,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          latitude: data['latitude']?.toDouble() ?? 0.0,
          longitude: data['longitude']?.toDouble() ?? 0.0,
          category: data['category'] ?? '',
          rating: data['rating']?.toDouble() ?? 0.0,
          createdBy: data['createdBy'] ?? '',
          createdAt: DateTime.parse(data['createdAt'] ?? now.toIso8601String()),
          updatedAt: DateTime.parse(data['updatedAt'] ?? now.toIso8601String()),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();
    } catch (e) {
      _logger.error('Error searching spots', error: e, tag: 'SpotsSembastDataSource');
      return [];
    }
  }
}
