import 'dart:developer' as developer;
import 'package:sembast/sembast.dart';
import 'package:spots/data/datasources/local/sembast_database.dart';

class RespectedListsSembastDataSource {
  final Database _database;

  RespectedListsSembastDataSource(this._database);

  /// Save respected lists for a user
  Future<void> saveRespectedLists(String userId, List<String> listNames) async {
    try {
      final store = SembastDatabase.respectsStore;
      final record = {
        'userId': userId,
        'listNames': listNames,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await store.record(userId).put(_database, record);
      developer.log('Saved ${listNames.length} respected lists for user $userId: $listNames', name: 'RespectedListsDataSource');
    } catch (e) {
      developer.log('Error saving respected lists: $e', name: 'RespectedListsDataSource');
      rethrow;
    }
  }

  /// Get respected lists for a user
  Future<List<String>> getRespectedLists(String userId) async {
    try {
      final store = SembastDatabase.respectsStore;
      final record = await store.record(userId).get(_database);

      developer.log('Looking for respected lists for user: $userId', name: 'RespectedListsDataSource');
      developer.log('Found record: ${record != null}', name: 'RespectedListsDataSource');

      if (record != null) {
        final listNames = List<String>.from(record['listNames'] as List);
        developer.log('Retrieved ${listNames.length} respected lists for user $userId: $listNames', name: 'RespectedListsDataSource');
        return listNames;
      }

      developer.log('No record found for user: $userId', name: 'RespectedListsDataSource');
      return [];
    } catch (e) {
      developer.log('Error getting respected lists: $e', name: 'RespectedListsDataSource');
      return [];
    }
  }

  /// Clear respected lists for a user
  Future<void> clearRespectedLists(String userId) async {
    try {
      final store = SembastDatabase.respectsStore;
      await store.record(userId).delete(_database);
      developer.log('Cleared respected lists for user: $userId', name: 'RespectedListsDataSource');
    } catch (e) {
      developer.log('Error clearing respected lists: $e', name: 'RespectedListsDataSource');
      rethrow;
    }
  }

  /// Get all respected lists (for admin purposes)
  Future<Map<String, List<String>>> getAllRespectedLists() async {
    try {
      final store = SembastDatabase.respectsStore;
      final records = await store.find(_database);
      
      final result = <String, List<String>>{};
      for (final record in records) {
        final userId = record.value['userId'] as String;
        final listNames = List<String>.from(record.value['listNames'] as List);
        result[userId] = listNames;
      }
      
      developer.log('Retrieved respected lists for ${result.length} users', name: 'RespectedListsDataSource');
      return result;
    } catch (e) {
      developer.log('Error getting all respected lists: $e', name: 'RespectedListsDataSource');
      return {};
    }
  }
}
